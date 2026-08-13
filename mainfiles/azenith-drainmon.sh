#!/system/bin/sh
#
# AZenith-RN9 :: CPU Activity Monitor (screen-state split)
# Custom addition for Redmi Note 9 (Helio G85 / 4GB)
#
# Mencatat aktivitas CPU per-aplikasi dan memisahkannya menjadi dua laporan
# di dalam SATU folder: /data/adb/.config/AZenith/drain/
#   - drain-screen-on.txt   : boros saat layar NYALA
#   - drain-screen-off.txt  : aktivitas CPU saat layar MATI
#

CFG="/data/adb/.config/AZenith"
DDIR="$CFG/drain"
TALLY_ON="$DDIR/.tally-on"
TALLY_OFF="$DDIR/.tally-off"
WAKE_OFF="$DDIR/.tally-wakelock"
SNAP="$DDIR/.snapshot"
LOG="$DDIR/drainmon.log"
LOCK="/dev/.azenith_drainmon.lock"

if [ -f "$LOCK" ]; then
	OLD=$(cat "$LOCK" 2>/dev/null)
	if [ -n "$OLD" ] && kill -0 "$OLD" 2>/dev/null; then
		exit 0
	fi
fi
echo $$ >"$LOCK"

mkdir -p "$DDIR"
: >"$SNAP"
[ -f "$TALLY_ON" ] || : >"$TALLY_ON"
[ -f "$TALLY_OFF" ] || : >"$TALLY_OFF"
[ -f "$WAKE_OFF" ] || : >"$WAKE_OFF"

log() {
	echo "$(date '+%m-%d %H:%M:%S') | $*" >>"$LOG"
	if [ "$(wc -c <"$LOG" 2>/dev/null || echo 0)" -gt 32768 ]; then
		tail -c 16384 "$LOG" >"$LOG.trim" 2>/dev/null && mv "$LOG.trim" "$LOG"
	fi
}

read_cfg() {
	_v=$(cat "$DDIR/$1" 2>/dev/null | tr -d ' \r\n')
	[ -z "$_v" ] && _v="$2"
	echo "$_v"
}

screen_is_on() {
	_s=$(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*' | cut -d= -f2)
	case "$_s" in
	Awake | Dreaming) return 0 ;;
	Asleep | Dozing) return 1 ;;
	esac
	dumpsys deviceidle 2>/dev/null | grep -qm1 'mScreenOn=true' && return 0
	return 1
}

# Ambil total CPU ticks (utime+stime) per nama paket dari /proc
snapshot() {
	for d in /proc/[0-9]*; do
		[ -r "$d/stat" ] || continue
		c=$(tr '\0' '\n' <"$d/cmdline" 2>/dev/null | head -n1)
		case "$c" in
		*.*.*) ;;
		*) continue ;;
		esac
		case "$c" in
		/*) continue ;;
		esac
		c=${c%%:*}
		t=$(awk '{print $14+$15}' "$d/stat" 2>/dev/null)
		[ -n "$t" ] && echo "$c $t"
	done | awk '{a[$1]+=$2} END{for(k in a) print k, a[k]}' | sort
}

# Gabungkan delta ke file tally kumulatif
accumulate() {
	_tally="$1"
	awk -v f="$_tally" '
		BEGIN { while ((getline line < f) > 0) { split(line, x, " "); a[x[1]] = x[2] } close(f) }
		{ a[$1] += $2 }
		END { for (k in a) if (a[k] > 0) print k, a[k] }
	' >"$_tally.tmp" && mv "$_tally.tmp" "$_tally"
}

# Catat wakelock aktif saat layar mati
sample_wakelock() {
	dumpsys power 2>/dev/null |
		sed -n '/Wake Locks:/,/^ *$/p' |
		grep -oE "'[^']+'" | tr -d "'" |
		awk 'NF{print $1, 1}' |
		awk '{a[$1]+=$2} END{for(k in a) print k, a[k]}' |
		accumulate "$WAKE_OFF"
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 3; done
sleep 45

log "===== Drain monitor start (pid $$) ====="
snapshot >"$SNAP"

while true; do
	INTERVAL=$(read_cfg interval 60)
	case "$INTERVAL" in '' | *[!0-9]*) INTERVAL=60 ;; esac
	[ "$INTERVAL" -lt 15 ] && INTERVAL=15

	if [ "$(read_cfg enabled 1)" != "1" ]; then
		sleep "$INTERVAL"
		continue
	fi

	# Tentukan bucket SEBELUM sampling, biar delta masuk ke kondisi yang benar
	if screen_is_on; then
		TARGET="$TALLY_ON"
		WAS_ON=1
	else
		TARGET="$TALLY_OFF"
		WAS_ON=0
	fi

	sleep "$INTERVAL"

	# Hanya hitung kalau kondisi layar tidak berubah selama interval,
	# supaya data screen-on dan screen-off tidak tercampur.
	if screen_is_on; then NOW_ON=1; else NOW_ON=0; fi

	snapshot >"$SNAP.new"

	if [ "$WAS_ON" -eq "$NOW_ON" ]; then
		awk '
			NR == FNR { p[$1] = $2; next }
			{ if ($1 in p) { d = $2 - p[$1]; if (d > 0) print $1, d } }
		' "$SNAP" "$SNAP.new" | accumulate "$TARGET"

		[ "$NOW_ON" -eq 0 ] && sample_wakelock
	fi

	mv "$SNAP.new" "$SNAP"
done
