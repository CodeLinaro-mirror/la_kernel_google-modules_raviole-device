// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright 2025 Google LLC
 */

#ifndef __GS_CHIPID_H__
#define __GS_CHIPID_H__

#include <linux/types.h>

u32 gs_chipid_get_type(void);
s32 gs_chipid_get_dvfs_version(void);
u32 gs_chipid_get_revision(void);
u32 gs_chipid_get_product_id(void);
int gs_chipid_get_ap_hw_tune_array(const u8 **array);
void gs_chipid_early_init(void);

#endif /* __GS_CHIPID_H__ */
