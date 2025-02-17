############################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
#
############################################################################

# Targets
TARGETS := .Xil
TARGETS += *.cache/
TARGETS += *.hw/
TARGETS += *.ip_user_files/
TARGETS += *.sim
TARGETS += xgui/
TARGETS += component.xml
TARGETS += *.jou 
TARGETS += *.log
TARGETS += *.xpr
TARGETS += *.png
TARGETS += *.jpg
TARGETS += *.jpeg

# Files for synthesis across all libraries
SYN_FILES += build_env.tcl

# Logo
LOGO := ../../logos/nandcompute.png

# Rules
.PHONY: all clean clean-all copy-logo

all: copy-logo
	vivado -mode batch -source $(LIB_NAME)_ip.tcl

copy-logo:
	cp $(LOGO) ./logo.png

clean: clean-all

clean-all:
	rm -rf $(TARGETS)
