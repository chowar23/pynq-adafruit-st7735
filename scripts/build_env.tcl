############################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
#
############################################################################

variable root_dir
variable lib_dir
variable proj_dir

variable IP_COMPANY_URL
variable IP_LIBRARY
variable IP_TAXONOMY
variable IP_VENDOR
variable IP_VENDOR_DISPLAY_NAME

# Directories
set root_dir [file normalize "../.."]
set lib_dir  [file normalize "$root_dir/lib"]
set proj_dir [file normalize "$root_dir/project"]

# IP Properties
set IP_COMPANY_URL "https://www.nandcompute.com"
set IP_LIBRARY     "ip"
set IP_TAXONOMY    "/Nand_Compute"
set IP_VENDOR      "nandcompute.com"
set IP_VENDOR_DISPLAY_NAME "Nand Compute"
