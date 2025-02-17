############################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
#
############################################################################

source ../../scripts/build_env.tcl

set ip_name "axis_frame_sync"
set ip_dir  "./"

# Create IP project and add files
create_project $ip_name $ip_dir -force
set_property ip_repo_paths $lib_dir [current_fileset]
update_ip_catalog

add_files -norecurse -fileset sources_1 "axis_frame_sync.vhd"
set_property top $ip_name [get_filesets sources_1]

# Package IP project
ipx::package_project -root_dir . -vendor $IP_VENDOR -library $IP_LIBRARY -taxonomy $IP_TAXONOMY
set_property name $ip_name [ipx::current_core]
set_property vendor_display_name {$IP_VENDOR_DISPLAY_NAME} [ipx::current_core]
set_property company_url {$IP_COMPANY_URL} [ipx::current_core]
ipx::save_core [ipx::current_core]

# Add Logo
set logo "logo.png"
ipx::add_file_group -type utility {} [ipx::current_core]
ipx::add_file $logo [ipx::get_file_groups xilinx_utilityxitfiles -of_objects [ipx::current_core]]
set_property type image [ipx::get_files $logo -of_objects [ipx::get_file_groups xilinx_utilityxitfiles -of_objects [ipx::current_core]]]

# Add clock / reset interfaces
ipx::infer_bus_interfaces xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]
ipx::associate_bus_interfaces -busif s_axis -clock axis_aclk [ipx::current_core]
ipx::associate_bus_interfaces -busif m_axis -clock axis_aclk [ipx::current_core]

# Create XGUI files
ipx::create_xgui_files [ipx::current_core]
ipx::save_core [ipx::current_core]
