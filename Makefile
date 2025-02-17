############################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
#
############################################################################

# Rules
.PHONY: all lib proj clean clean-all clean-lib clean-proj

all: lib proj

lib:
	$(MAKE) -C lib/ all

proj:
	$(MAKE) -C project/ all

clean: clean-all

clean-all: clean-lib clean-proj
	rm -rf *.jou *.log *.str

clean-lib:
	$(MAKE) -C lib/ clean

clean-proj:
	$(MAKE) -C project/ clean
	
