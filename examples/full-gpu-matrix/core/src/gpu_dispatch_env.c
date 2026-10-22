/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *  See gpu_dispatch_env.h. Snapshots up to a small fixed number of distinct env
 *  variables, each under its own pthread_once / InitOnceExecuteOnce gate.
 *  Adapted from: vmaf/core/src/gpu_dispatch_env.{h,c}.
 */
// NOLINTNEXTLINE(bugprone-reserved-identifier,cert-dcl37-c,cert-dcl51-cpp) /* WHY: POSIX feature test macro required for strdup before system headers */
#define _POSIX_C_SOURCE 200809L /* strdup */

#include "gpu_dispatch_env.h"

#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#define strdup_compat _strdup
#else
#include <pthread.h>
#define strdup_compat strdup
#endif

/* Small fixed registry: one slot per distinct var_name pointer seen. The set of
 * dispatch env vars is tiny and known at compile time, so a linear scan is fine
 * and keeps the helper allocation-free past the one-time strdup. */
#define PROJ_ENV_MAX_VARS 8

struct env_slot {
    const char *name; /* key: the caller's string-literal pointer */
    const char *value;
};

static struct env_slot g_slots[PROJ_ENV_MAX_VARS];
static int g_slot_count = 0;

#ifdef _WIN32
static CRITICAL_SECTION g_lock;
static INIT_ONCE g_lock_once = INIT_ONCE_STATIC_INIT;
static BOOL CALLBACK init_lock(PINIT_ONCE o, PVOID p, PVOID *c)
{
    (void)o;
    (void)p;
    (void)c;
    InitializeCriticalSection(&g_lock);
    return TRUE;
}
#else
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;
#endif

const char *proj_gpu_dispatch_env_get(const char *var_name)
{
    int i;
    const char *raw;
    const char *copy = NULL;

    if (!var_name)
        return NULL;

#ifdef _WIN32
    InitOnceExecuteOnce(&g_lock_once, init_lock, NULL, NULL);
    EnterCriticalSection(&g_lock);
#else
    pthread_mutex_lock(&g_lock);
#endif

    int found = 0;
    for (i = 0; i < g_slot_count; i++) {
        if (g_slots[i].name == var_name) {
            copy = g_slots[i].value;
            found = 1;
            break;
        }
    }
    if (!found && g_slot_count < PROJ_ENV_MAX_VARS) {
        // NOLINTNEXTLINE(concurrency-mt-unsafe) /* WHY: getenv serialized under g_lock mutex */
        raw = getenv(var_name); /* serialised by the lock above */
        g_slots[g_slot_count].name = var_name;
        g_slots[g_slot_count].value = raw ? strdup_compat(raw) : NULL;
        copy = g_slots[g_slot_count].value;
        g_slot_count++;
    }
#ifdef _WIN32
    LeaveCriticalSection(&g_lock);
#else
    pthread_mutex_unlock(&g_lock);
#endif
    return copy;
}
