/**
 *
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *     Licensed under the EUPL-1.2 (the "Licence"). See LICENSE.
 *
 */

/* version.c — library version + result-string accessors. */

#include "project/project.h"

int proj_version(void)
{
    return PROJ_VERSION_INT;
}

const char *proj_version_string(void)
{
    return PROJ_VERSION_STR;
}

const char *proj_result_str(proj_result r)
{
    switch (r) {
    case PROJ_OK:
        return "ok";
    case PROJ_ERR_INVALID:
        return "invalid argument";
    case PROJ_ERR_NOMEM:
        return "out of memory";
    case PROJ_ERR_RANGE:
        return "value out of range";
    case PROJ_ERR_ABI:
        return "ABI major mismatch / corrupt framing";
    case PROJ_ERR_ABSENT:
        return "data not present";
    case PROJ_ERR_TRUNCATED:
        return "buffer truncated";
    case PROJ_ERR_UNSUPPORTED:
        return "unsupported";
    default:
        return "unknown error";
    }
}
