// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (c) 2019 MediaTek Inc.
 */

#include "kd_imgsensor.h"

#include "mclk/mclk.h"
#include "regulator/regulator.h"
#include "gpio/gpio.h"

#include "imgsensor_hw.h"
#include "imgsensor_cfg_table.h"
enum IMGSENSOR_RETURN (*hw_open[IMGSENSOR_HW_ID_MAX_NUM])
	(struct IMGSENSOR_HW_DEVICE **) = {
	imgsensor_hw_mclk_open,
	imgsensor_hw_regulator_open,
	imgsensor_hw_gpio_open
};

struct IMGSENSOR_HW_CFG imgsensor_custom_config[] = {
	{
		IMGSENSOR_SENSOR_IDX_MAIN,
		IMGSENSOR_I2C_DEV_0,
		{
			{IMGSENSOR_HW_PIN_MCLK,  IMGSENSOR_HW_ID_MCLK},
			{IMGSENSOR_HW_PIN_AVDD,  IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_AVDD1, IMGSENSOR_HW_ID_GPIO}, //front AVDD
			{IMGSENSOR_HW_PIN_DOVDD, IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_DVDD,  IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_DVDD1, IMGSENSOR_HW_ID_GPIO}, //Front DVDD
			{IMGSENSOR_HW_PIN_AFVDD, IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_RST,   IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_RST1,	 IMGSENSOR_HW_ID_GPIO}, //Front Reset
			{IMGSENSOR_HW_PIN_NONE,  IMGSENSOR_HW_ID_NONE},
		},
	},
	{
		IMGSENSOR_SENSOR_IDX_SUB,
		IMGSENSOR_I2C_DEV_1,
		{
			{IMGSENSOR_HW_PIN_MCLK,  IMGSENSOR_HW_ID_MCLK},
			{IMGSENSOR_HW_PIN_AVDD,  IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_DOVDD, IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_DVDD,  IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_RST,   IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_NONE, IMGSENSOR_HW_ID_NONE},
		},
	},
	{
		IMGSENSOR_SENSOR_IDX_MAIN2,
		IMGSENSOR_I2C_DEV_2,
		{
			{IMGSENSOR_HW_PIN_MCLK,  IMGSENSOR_HW_ID_MCLK},
			{IMGSENSOR_HW_PIN_AVDD,  IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_DOVDD, IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_DVDD1, IMGSENSOR_HW_ID_GPIO}, //Front DVDD
			{IMGSENSOR_HW_PIN_RST,   IMGSENSOR_HW_ID_GPIO},
			{IMGSENSOR_HW_PIN_RST1,  IMGSENSOR_HW_ID_GPIO}, //Front Reset
			{IMGSENSOR_HW_PIN_NONE,  IMGSENSOR_HW_ID_NONE},
		},
	},
	{IMGSENSOR_SENSOR_IDX_NONE}
};

struct IMGSENSOR_HW_POWER_SEQ platform_power_sequence[] = {
	{NULL}
};

struct IMGSENSOR_HW_POWER_SEQ sensor_power_sequence[] = {
#if defined(S5KJN1_MIPI_RAW)
	{
		SENSOR_DRVNAME_S5KJN1_MIPI_RAW,
		{
			{RST, Vol_Low, 1},
			{RST1, Vol_Low, 1},
			{DOVDD, Vol_High, 1},
			{DVDD, Vol_High, 1},
			{DVDD1, Vol_High, 1}, //Front dvdd
			{AFVDD, Vol_High, 1},
			{AVDD, Vol_High, 1},
			{RST1, Vol_High, 1}, //Front reset
			{AVDD1, Vol_High, 1}, //Front AVDD
			{SensorMCLK, Vol_High, 2},
			{RST1, Vol_Low, 0}, //Front reset
			{RST, Vol_High, 5}
		},
	},
#endif

#if defined(SC501CS_MIPI_RAW)
	{
		SENSOR_DRVNAME_SC501CS_MIPI_RAW,
		{
			{RST, Vol_Low, 1},
			{DOVDD, Vol_High, 1},
			{DVDD, Vol_High, 1},
			{AVDD, Vol_High, 1},
			{RST, Vol_High, 1},
			{RST, Vol_Low, 1},
			{SensorMCLK, Vol_High, 1},
			{RST, Vol_High, 5},
		},
	},
#endif

#if defined(GC02M1_MIPI_RAW)
	{
		SENSOR_DRVNAME_GC02M1_MIPI_RAW,
		{
			{RST, Vol_Low, 2},
			{RST1, Vol_Low, 1},
			{DOVDD, Vol_High, 1},
			{DVDD1, Vol_High, 1}, //Front dvdd
			{RST1, Vol_High, 1}, //Front reset
			{AVDD, Vol_High, 1},
			{SensorMCLK, Vol_High, 2},
			{RST1, Vol_Low, 0}, //Front reset
			{RST, Vol_High, 2},
		},
	},
#endif
};
