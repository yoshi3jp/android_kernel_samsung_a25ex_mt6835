// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (c) 2023 Samsung Electronics Inc.
 */

#include "imgsensor_vendor_rom_config_aay_v25ex.h"

const struct imgsensor_vendor_rom_info vendor_rom_info[] = {
	{SENSOR_POSITION_REAR,  S5KJN1_SENSOR_ID,  &rear_s5kjn1_cal_addr},
	{SENSOR_POSITION_REAR2, GC02M1_SENSOR_ID,  &rear2_gc02m1_cal_addr},
	{SENSOR_POSITION_FRONT, SC501CS_SENSOR_ID, &front_sc501cs_cal_addr},
};
