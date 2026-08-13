#!/system/bin/sh
# AZenith RN9 fork - screen-off app hibernation helper.
# Invoked directly by the daemon: azenith-hibernate.sh apply | release
# Based on AZenith by Zexshia, Apache License 2.0.

ECO_DIR=/data/adb/.config/AZenith/eco
LEGACY_ECO_DIR=/data/adb/.config/AZenith/hibernate
LIST=$ECO_DIR/hibernate.list
LOG=$ECO_DIR/hibernate.log
STATE=$ECO_DIR/.applied
MAXLOG=131072

# Keep upgrades from the first RN9 fork working if the canonical list is absent.
if [ ! -f "$LIST" ] && [ -f "$LEGACY_ECO_DIR/hibernate.list" ]; then
	mkdir -p "$ECO_DIR"
	cp -f "$LEGACY_ECO_DIR/hibernate.list" "$LIST"
fi

log() {
	[ -f "$LOG" ] && [ "$(stat -c %s "$LOG" 2>/dev/null || echo 0)" -gt "$MAXLOG" ] && : >"$LOG"
	echo "$(date '+%m-%d %H:%M:%S') $1" >>"$LOG"
}

# Read the user list, ignoring blank lines and # comments.
pkglist() {
	[ -f "$LIST" ] || return 0
	sed -e 's/#.*//' -e 's/[[:space:]]//g' "$LIST" | grep -v '^$'
}

is_installed() {
	pm path "$1" >/dev/null 2>&1
}

# Never hibernate the foreground app, ourselves, or anything critical.
is_protected() {
	case "$1" in
	android | com.android.systemui | com.android.phone | zx.azenith | *.inputmethod* | com.google.android.gms)
		return 0
		;;
	esac
	return 1
}

freeze() {
	p=$1
	for op in RUN_ANY_IN_BACKGROUND RUN_IN_BACKGROUND WAKE_LOCK START_FOREGROUND; do
		appops set "$p" $op ignore >/dev/null 2>&1
	done
	am set-standby-bucket "$p" restricted >/dev/null 2>&1
	cmd deviceidle whitelist -"$p" >/dev/null 2>&1
	am force-stop "$p" >/dev/null 2>&1
}

thaw() {
	p=$1
	for op in RUN_ANY_IN_BACKGROUND RUN_IN_BACKGROUND WAKE_LOCK START_FOREGROUND; do
		appops set "$p" $op allow >/dev/null 2>&1
	done
	am set-standby-bucket "$p" active >/dev/null 2>&1
}

case "$1" in
apply)
	[ -f "$STATE" ] && exit 0
	n=0
	for p in $(pkglist); do
		is_protected "$p" && {
			log "skip (protected): $p"
			continue
		}
		is_installed "$p" || {
			log "skip (not installed): $p"
			continue
		}
		freeze "$p"
		n=$((n + 1))
	done
	: >"$STATE"
	log "hibernate applied to $n package(s)"
	;;
release)
	[ -f "$STATE" ] || exit 0
	n=0
	for p in $(pkglist); do
		is_protected "$p" && continue
		is_installed "$p" || continue
		thaw "$p"
		n=$((n + 1))
	done
	rm -f "$STATE"
	log "hibernate released for $n package(s)"
	;;
*)
	echo "usage: $0 apply|release" >&2
	exit 1
	;;
esac

exit 0
