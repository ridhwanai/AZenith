#!/system/bin/sh

#
# Copyright (C) 2026-2027 Zexshia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

q() {
    pkill -9 -f "$1"
}

resetprop | awk -F'[][]' '/persist\.sys\.azenith/ {print $2}' | while read -r prop; do
    resetprop -p --delete "$prop"
done

for prop in persist.sys.rianixia.learning_enabled persist.sys.rianixia.thermalcore-bigdata.path; do
    resetprop -p --delete "$prop"
done

rm -rf \
    "/data/adb/.config/AZenith" \
    "/data/AZenith" \
    "/data/data/zx.azenith"
: > "/data/adb/modules/AZenith/remove"

q sys.azenith-rianixiathermalcore
q sys.azenith-service
q sys.azenith-appmonitoring
    
pm uninstall zx.azenith >/dev/null 2>&1 &

for dir in "/data/adb/ap/bin" "/data/adb/ksu/bin"; do
    [ -d "$dir/zx" ] && rm -rf "$dir/zx"
done

for dir in "/data/adb/ap/bin" "/data/adb/ksu/bin"; do
    [ -d "$dir" ] && find "$dir" -name "sys.azenith-*" -exec rm -f {} +
done

# RN9 fork: make sure no package is left frozen after uninstall
HIBLIST=/data/adb/.config/AZenith/eco/hibernate.list
if [ -f "$HIBLIST" ]; then
	for p in $(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$HIBLIST" | grep -v '^$'); do
		for op in RUN_ANY_IN_BACKGROUND RUN_IN_BACKGROUND WAKE_LOCK START_FOREGROUND; do
			appops set "$p" $op allow >/dev/null 2>&1
		done
		am set-standby-bucket "$p" active >/dev/null 2>&1
	done
fi
rm -f /dev/.azenith_drainmon.lock
