/**
 *
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *     Licensed under the BSD+Patent License (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *         https://opensource.org/licenses/BSDplusPatent
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 */

/*
 * project.h — umbrella public header for libproject.
 *
 * libproject is the shared core of a native (C/C++) + GPU project: a versioned,
 * append-only side-data interop ABI (interop.h) plus whatever contracts your
 * filters / consumers both depend on. The FFmpeg vf_project_* filters and any
 * downstream tooling both link this library or vendor the same translation
 * units.
 *
 * ABI surface: everything under include/project/ is public and stability-tagged.
 * Internal helpers never appear here.
 */
#ifndef PROJECT_PROJECT_H
#define PROJECT_PROJECT_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- Library version (SemVer; tracks git tags v<MAJOR>.<MINOR>.<PATCH>) --- */
#define PROJ_VERSION_MAJOR 0
#define PROJ_VERSION_MINOR 1
#define PROJ_VERSION_PATCH 0
#define PROJ_VERSION_STR "0.1.0"

/* Packed integer version for runtime comparisons: (major<<16)|(minor<<8)|patch. */
#define PROJ_VERSION_INT                                                                           \
    ((PROJ_VERSION_MAJOR << 16) | (PROJ_VERSION_MINOR << 8) | (PROJ_VERSION_PATCH))

/* Returns the compiled-in PROJ_VERSION_INT of the linked library. */
int proj_version(void);

/* Returns the compiled-in PROJ_VERSION_STR of the linked library. */
const char *proj_version_string(void);

/* ---- Result codes ------------------------------------------------------- *
 * Every libproject entry point that can fail returns a proj_result. Negative
 * values are errors; PROJ_OK is success. No bare -1 crosses an API boundary.
 */
typedef enum proj_result {
    PROJ_OK = 0,              /* success                                        */
    PROJ_ERR_INVALID = -1,    /* invalid argument / NULL where non-NULL needed  */
    PROJ_ERR_NOMEM = -2,      /* allocation failed                              */
    PROJ_ERR_RANGE = -3,      /* value outside the documented valid range       */
    PROJ_ERR_ABI = -4,        /* blob ABI major mismatch / corrupt framing      */
    PROJ_ERR_ABSENT = -5,     /* requested section / data not present           */
    PROJ_ERR_TRUNCATED = -6,  /* buffer shorter than its self-described size    */
    PROJ_ERR_UNSUPPORTED = -7 /* feature not compiled in / not available       */
} proj_result;

/* Human-readable, static string for a proj_result. Never NULL. */
const char *proj_result_str(proj_result r);

#ifdef __cplusplus
}
#endif
#endif /* PROJECT_PROJECT_H */
