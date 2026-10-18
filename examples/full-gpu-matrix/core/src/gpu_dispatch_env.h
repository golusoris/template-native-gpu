/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *  Thread-safe, once-only snapshot of GPU dispatch env variables.
 *
 *  getenv() is concurrency-mt-unsafe (POSIX.1-2008 §2.2.2) against a concurrent
 *  setenv/putenv. This helper snapshots a variable once under pthread_once
 *  (POSIX) / InitOnceExecuteOnce (Windows) so every backend's dispatch module
 *  can share one safe code path.
 *  Adapted from: vmaf/core/src/gpu_dispatch_env.h.
 *
 *  Contract: set the variable before the first GPU frame is submitted. Later
 *  setenv() calls are not observed — by design. NULL => unset at snapshot time.
 */
#ifndef PROJ_GPU_DISPATCH_ENV_H_
#define PROJ_GPU_DISPATCH_ENV_H_

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Return a once-snapshotted copy of the environment variable @var_name. The
 * returned pointer is stable for the process lifetime; distinct var_name
 * strings produce independent snapshots.
 */
const char *proj_gpu_dispatch_env_get(const char *var_name);

#ifdef __cplusplus
}
#endif

#endif /* PROJ_GPU_DISPATCH_ENV_H_ */
