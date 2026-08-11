/*
 * Screen-off ECO controller (Redmi Note 9 fork).
 * Based on AZenith by Zexshia, licensed under the Apache License 2.0.
 */

#include "AZenith.h"

#define ECO_CONFIG_DIR       "/data/adb/.config/AZenith/eco"
#define ECO_ENABLED_FILE     ECO_CONFIG_DIR "/enabled"
#define ECO_DELAY_FILE       ECO_CONFIG_DIR "/delay"
#define ECO_HIBERNATE_SCRIPT "/data/adb/modules/AZenith/azenith-hibernate.sh"

static int read_int_file(const char* path, int fallback) {
    FILE* fp = fopen(path, "r");
    if (!fp)
        return fallback;
    int value = fallback;
    if (fscanf(fp, "%d", &value) != 1)
        value = fallback;
    fclose(fp);
    return value;
}

static bool eco_enabled(void) {
    return read_int_file(ECO_ENABLED_FILE, 1) != 0;
}

static int eco_delay_sec(void) {
    int delay = read_int_file(ECO_DELAY_FILE, 300);
    if (delay < 10)
        delay = 10;
    if (delay > 7200)
        delay = 7200;
    return delay;
}

/**
 * @brief Returns true when the screen has been off long enough to drop into ECO.
 */
bool screen_off_eco_due(DaemonContext* ctx, int screen_state) {
    if (!ctx || screen_state != 0)
        return false;
    if (ctx->grace_period_active || ctx->screen_off_eco_applied)
        return false;
    if (ctx->screen_off_timer == 0 || !eco_enabled())
        return false;
    return difftime(time(NULL), ctx->screen_off_timer) >= (double)eco_delay_sec();
}

/**
 * @brief Milliseconds remaining until the ECO threshold, or -1 when idle.
 */
int screen_off_eco_wait_ms(DaemonContext* ctx) {
    if (!ctx || ctx->prev_screen_state != 0 || ctx->screen_off_eco_applied)
        return -1;
    if (ctx->screen_off_timer == 0 || !eco_enabled())
        return -1;
    double remaining = (double)eco_delay_sec() - difftime(time(NULL), ctx->screen_off_timer);
    if (remaining <= 0.0)
        return 0;
    return (int)(remaining * 1000.0);
}

void screen_off_eco_hibernate(void) {
    if (access(ECO_HIBERNATE_SCRIPT, F_OK) != 0)
        return;
    (void)systemv("sh %s apply", ECO_HIBERNATE_SCRIPT);
}

void screen_off_eco_release(void) {
    if (access(ECO_HIBERNATE_SCRIPT, F_OK) != 0)
        return;
    (void)systemv("sh %s release", ECO_HIBERNATE_SCRIPT);
}
