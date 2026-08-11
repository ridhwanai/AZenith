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
 */

#include <AZenith.h>

/**
 * @brief Checks if the module properties have been renamed or modified by a 3rd party.
 */
void is_kanged(void) {
    /* RN9 fork: built from source by the device owner, fork detection disabled. */
    return;
}

void check_module_version(void) {
    /* RN9 fork: version is injected at build time; mismatch abort disabled. */
    snprintf(DAEMON_VERSION, sizeof(DAEMON_VERSION), "%s", MODULE_VERSION);
}
