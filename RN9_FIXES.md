# AZenith 5.1 RN9 fixes

This source contains the RN9 fixes requested for the Redmi Note 9 fork.

## Changes

1. **Hibernate configuration path unified**
   - Canonical path: `/data/adb/.config/AZenith/eco/`
   - `hibernate.list`, `enabled`, `delay`, `.applied`, and `hibernate.log` now use the same path as the native daemon.
   - Existing `/data/adb/.config/AZenith/hibernate/` data is migrated/fallback-read so upgrades do not lose the user's list.
   - `azenith-report` and uninstall cleanup now use the same canonical path.

2. **Real battery monitoring added**
   - `AppMonitor` exports battery current, voltage, power, temperature, screen state, charging state, and timestamp.
   - Samples are stored in `/data/adb/.config/AZenith/drain/battery_samples.csv` every 5 seconds.
   - Manager UI displays live screen-on/screen-off state, current, voltage, power, average current by screen state, and estimated `%/hour` when enough capacity data exists.
   - The existing CPU tally remains a CPU-activity report and is no longer treated as direct battery measurement.

3. **Performance Apps menu added**
   - New bottom navigation entry: `Performance` immediately before `Hibernasi`.
   - Installed applications can be enabled/disabled for AZenith Performance Profile.
   - Existing per-app JSON settings are preserved.
   - Newly enabled applications receive the default config and inherit global Performance settings.
   - Existing `azenithApplist.json` defaults, including Mobile Legends, remain intact.

## Recommended verification

From the repository root:

```bash
bash -n mainfiles/azenith-hibernate.sh
bash -n mainfiles/azenith-drainmon.sh
bash -n mainfiles/azenith-report
bash -n mainfiles/customize.sh
bash -n mainfiles/uninstall.sh

grep -RIn '/data/adb/.config/AZenith/eco' archdaemon mainfiles manager/app/src/main/java | head -100

grep -RIn 'battery_current_ma\|battery_voltage_mv\|battery_samples.csv' manager/app/src/main/java mainfiles

grep -RIn 'nav_performance\|PerformanceAppsScreen\|setPerformanceEnabled' manager/app/src/main/java manager/app/src/main/res
```

Build the manager APK locally:

```bash
cd manager
chmod +x ./gradlew
./gradlew clean assembleRelease
cd ..
```

Or run the existing GitHub Actions workflow to build both the APK and flashable module ZIP.

## Device-side verification after installation

Run as root on the Redmi Note 9:

```bash
cat /data/adb/.config/AZenith/eco/enabled
cat /data/adb/.config/AZenith/eco/delay
cat /data/adb/.config/AZenith/eco/hibernate.list

tail -n 20 /data/adb/.config/AZenith/drain/battery_samples.csv
cat /data/adb/.config/AZenith/app_status

azenith-report

grep -E 'Screen-off ECO|hibernate applied|hibernate released' /data/adb/.config/AZenith/*.log /data/adb/.config/AZenith/eco/*.log 2>/dev/null | tail -50
```

For the Performance menu, enable/disable an app and verify that the JSON changes:

```bash
cat /data/adb/.config/AZenith/gamelist/azenithApplist.json
```

Then launch the selected app and check the AZenith daemon log for the game/performance transition.

## Packaging fix
The RN9 helper scripts `azenith-hibernate.sh`, `azenith-drainmon.sh`, and `azenith-report` are now explicitly extracted by `mainfiles/customize.sh`. The previous build listed these files in the flashable ZIP but never extracted them into `/data/adb/modules/AZenith`, so `sys.azenith-service` could not execute the hibernation helper and the drain monitor could not start.
