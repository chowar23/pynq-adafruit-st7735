############################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
#
############################################################################

# Subdirectories: Find subdirectories with Makefile in them
SUBDIRS := $(dir $(shell find . -mindepth 2 -name Makefile))
SUBDIRS_CLEAN := $(SUBDIRS:%=clean-%)

# Rules
.PHONY: all clean $(SUBDIRS) $(SUBDIRS_CLEAN)

all: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@

clean: $(SUBDIRS_CLEAN)
$(SUBDIRS_CLEAN):
	$(MAKE) -C $(@:clean-%=%) clean 

