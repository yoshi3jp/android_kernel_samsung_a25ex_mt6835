/*
 * Header file for Panel Driver
 *
 * Copyright (c) 2019 Samsung Electronics
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef __NT36528A_A25EX_00_RESOL_H__
#define __NT36528A_A25EX_00_RESOL_H__

#include <dt-bindings/display/panel-display.h>
#include "../panel.h"
#include "tft_common.h"

enum {
	NT36528A_A25EX_00_DISPLAY_MODE_720x1600_60HS,
	MAX_NT36528A_A25EX_00_DISPLAY_MODE,
};

enum {
	NT36528A_A25EX_00_RESOL_720x1600,
	MAX_NT36528A_A25EX_00_RESOL,
};

enum {
	NT36528A_A25EX_00_VRR_60HS,
	MAX_NT36528A_A25EX_00_VRR,
};

struct panel_vrr nt36528a_a25ex_00_default_panel_vrr[] = {
	[NT36528A_A25EX_00_VRR_60HS] = {
		.fps = 60,
		.te_sw_skip_count = 0,
		.te_hw_skip_count = 0,
		.mode = VRR_HS_MODE,
	},
};

static struct panel_vrr *nt36528a_a25ex_00_default_vrrtbl[] = {
	&nt36528a_a25ex_00_default_panel_vrr[NT36528A_A25EX_00_VRR_60HS],
};

static struct panel_resol nt36528a_a25ex_00_default_resol[] = {
	[NT36528A_A25EX_00_RESOL_720x1600] = {
		.w = 720,
		.h = 1600,
		.comp_type = PN_COMP_TYPE_NONE,
		.available_vrr = nt36528a_a25ex_00_default_vrrtbl,
		.nr_available_vrr = ARRAY_SIZE(nt36528a_a25ex_00_default_vrrtbl),
	}
};

#if defined(CONFIG_USDM_PANEL_DISPLAY_MODE)
static struct common_panel_display_mode nt36528a_a25ex_00_display_mode[] = {
	[NT36528A_A25EX_00_DISPLAY_MODE_720x1600_60HS] = {
		.name = PANEL_DISPLAY_MODE_720x1600_60HS,
		.resol = &nt36528a_a25ex_00_default_resol[NT36528A_A25EX_00_RESOL_720x1600],
		.vrr = &nt36528a_a25ex_00_default_panel_vrr[NT36528A_A25EX_00_VRR_60HS],
	},
};

static struct common_panel_display_mode *nt36528a_a25ex_00_display_mode_array[] = {
	&nt36528a_a25ex_00_display_mode[NT36528A_A25EX_00_DISPLAY_MODE_720x1600_60HS],
};

static struct common_panel_display_modes nt36528a_a25ex_00_display_modes = {
	.num_modes = ARRAY_SIZE(nt36528a_a25ex_00_display_mode_array),
	.modes = (struct common_panel_display_mode **)&nt36528a_a25ex_00_display_mode_array,
};
#endif /* CONFIG_USDM_PANEL_DISPLAY_MODE */
#endif /* __NT36528A_A25EX_00_RESOL_H__ */
