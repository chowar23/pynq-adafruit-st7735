############################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
#
############################################################################

PROJECT_NAME := lcd_demo_arty_z7_20

PROJ_FILES := system_project.tcl
PROJ_FILES += system_constr.xdc
PROJ_FILES += system_top.vhd
PROJ_FILES += system_bd.tcl

LIB_DEPS += axi_af_st7735
LIB_DEPS += axis_bgr888_to_rgb565
LIB_DEPS += axis_frame_sync

include ../../scripts/project.mk
