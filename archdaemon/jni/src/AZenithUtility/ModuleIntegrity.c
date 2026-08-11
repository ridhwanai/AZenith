/*
 * Copyright (C) 2024-2025 Rem01Gaming x Zexshia
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * RN9 Edition: integrity and version gates are intentionally disabled so the
 * module can be renamed. Both functions are kept as no-ops because they are
 * declared in AZenith.h and called from System.c, DaemonStartup.c,
 * InotifyWatcher.c and ProfileUtility.c.
 */

#include <AZenith.h>

/**
 * @brief Disabled in this fork: module renaming is allowed.
 */
void is_kanged(void) {
    return;
}

/**
 * @brief Disabled in this fork: version mismatch no longer aborts the daemon.
 */
void check_module_version(void) {
    return;
}