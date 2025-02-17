############################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
#
############################################################################

set proj_name "lcd_demo_arty_z7_20"
set part "xc7z020clg400-1"

# Create project
set proj_dir "./"
set proj_target_language "VHDL"
set board [lindex [lsearch -all -inline [get_board_parts] "*arty-z7-20*"] end]

create_project $proj_name $proj_dir -part $part -force
set_property board_part $board [current_project]
set_property target_language $proj_target_language [current_project]

set_property ip_repo_paths "../../../lib" [current_project]
update_ip_catalog

# Add files
add_files -norecurse -fileset sources_1 "system_top.vhd"
add_files -norecurse -fileset sources_1 "system_constr.xdc"
set_property top "system_top" [current_fileset]

# Create block design
create_bd_design "system"
source "system_bd.tcl"
save_bd_design
validate_bd_design

make_wrapper -files [get_files ${proj_name}.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse ${proj_name}.gen/sources_1/bd/system/hdl/system_wrapper.vhd
update_compile_order -fileset sources_1

# Launch Synthesis and wait
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Launch Implementation and wait
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1 

