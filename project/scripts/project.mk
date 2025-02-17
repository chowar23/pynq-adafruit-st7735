############################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
#
############################################################################

# Targets
TARGETS := .Xil
TARGETS += *.cache/
TARGETS += *.gen/
TARGETS += *.hw/
TARGETS += *.ip_user_files/
TARGETS += *.runs/
TARGETS += *.sim/
TARGETS += *.srcs/
TARGETS += NA/
TARGETS += *.jou 
TARGETS += *.log
TARGETS += *.xpr 

# Files for synthesis across all libraries
PROJ_FILES += build_env.tcl

# Rules
.PHONY: all clean clean-all

all:
	vivado -mode batch -source system_project.tcl 

clean: clean-all

clean-all:
	rm -rf $(TARGETS)
