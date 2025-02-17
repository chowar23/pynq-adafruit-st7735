############################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
#
# Description: Create board design
#
############################################################################

############################################################################
# Interface Ports
############################################################################
# Adafruit ST7735 TFT LCD Pins
create_bd_port -dir I af_st7735_miso
create_bd_port -dir O af_st7735_mosi
create_bd_port -dir O af_st7735_sck
create_bd_port -dir O af_st7735_tft_cs_n
create_bd_port -dir O af_st7735_card_cs_n
create_bd_port -dir O af_st7735_rst_n
create_bd_port -dir O af_st7735_dc
create_bd_port -dir O af_st7735_lite

############################################################################
# Processing System 7
############################################################################
set CLK_FREQ_HZ  100e6
set CLK_FREQ_MHZ [expr int($CLK_FREQ_HZ / 1.0e6)]

set sys_ps7_name sys_ps7_0
set sys_ps7 [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 $sys_ps7_name]

# Apply board presets (i.e. for clocking)
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config { \
    make_external "FIXED_IO, DDR" \
    apply_board_preset "1" \
    Master "Disable" \
    Slave "Disable"}  $sys_ps7

# Apply config settings
set_property -dict [list \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ $CLK_FREQ_MHZ \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_USE_S_AXI_HP0 {1}] $sys_ps7

set sys_clk [get_bd_pins $sys_ps7_name/FCLK_CLK0]

connect_bd_net $sys_clk  [get_bd_pins $sys_ps7_name/M_AXI_GP0_ACLK]
connect_bd_net $sys_clk  [get_bd_pins $sys_ps7_name/S_AXI_HP0_ACLK]

############################################################################
# System Reset
############################################################################
set sys_rstgen_name sys_rstgen_0
set sys_rstgen [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset $sys_rstgen_name]
set_property -dict [list CONFIG.C_EXT_RST_WIDTH {1}] $sys_rstgen

connect_bd_net $sys_clk [get_bd_pins $sys_rstgen_name/slowest_sync_clk]
connect_bd_net [get_bd_pins $sys_rstgen_name/ext_reset_in] [get_bd_pins $sys_ps7_name/FCLK_RESET0_N]

set sys_periph_rst        [get_bd_pins $sys_rstgen_name/peripheral_reset]
set sys_periph_rstn       [get_bd_pins $sys_rstgen_name/peripheral_aresetn]
set sys_interconnect_rstn [get_bd_pins $sys_rstgen_name/interconnect_aresetn]

############################################################################
# AXI Adafruit ST7735 SPI Module (memory mapped)
############################################################################
set axi_af_st7735_name axi_af_st7735_0
set axi_af_st7735 [create_bd_cell -type ip -vlnv nandcompute.com:ip:axi_af_st7735 $axi_af_st7735_name]

connect_bd_net $sys_clk         [get_bd_pins $axi_af_st7735_name/axi_aclk]
connect_bd_net $sys_periph_rstn [get_bd_pins $axi_af_st7735_name/axi_aresetn]

############################################################################
# AXI Stream Convert BGR888 Data to RGB565
############################################################################
set axis_bgr888_to_rgb565_name axis_bgr888_to_rgb565_0
set axis_bgr888_to_rgb565 [create_bd_cell -type ip -vlnv nandcompute.com:ip:axis_bgr888_to_rgb565 $axis_bgr888_to_rgb565_name]

connect_bd_net $sys_clk         [get_bd_pins $axis_bgr888_to_rgb565_name/axis_aclk]
connect_bd_net $sys_periph_rstn [get_bd_pins $axis_bgr888_to_rgb565_name/axis_aresetn]

connect_bd_intf_net [get_bd_intf_pins $axis_bgr888_to_rgb565_name/m_axis] [get_bd_intf_pins $axi_af_st7735_name/s_axis]

############################################################################
# AXI Stream Frame Synchronizer
############################################################################
set axis_frame_sync_name axis_frame_sync_0
set axis_frame_sync [create_bd_cell -type ip -vlnv nandcompute.com:ip:axis_frame_sync $axis_frame_sync_name]
set_property -dict [list \
    CONFIG.CLOCK_RATE_HZ $CLK_FREQ_HZ \
    CONFIG.FRAME_RATE_HZ {24}] $axis_frame_sync

connect_bd_net $sys_clk         [get_bd_pins $axis_frame_sync_name/axis_aclk]
connect_bd_net $sys_periph_rstn [get_bd_pins $axis_frame_sync_name/axis_aresetn]

connect_bd_intf_net [get_bd_intf_pins $axis_frame_sync_name/m_axis] [get_bd_intf_pins $axis_bgr888_to_rgb565_name/s_axis]

############################################################################
# AXI DMA - Direct Memory Access
############################################################################
set axi_dma_name axi_dma_0
set axi_dma [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma $axi_dma_name]
set_property -dict [list \
  CONFIG.c_include_sg {0} \
  CONFIG.c_sg_length_width {18} \
  CONFIG.c_sg_include_stscntrl_strm {0} \
  CONFIG.c_include_s2mm {0} \
  CONFIG.c_m_axis_mm2s_tdata_width {8} \
  CONFIG.c_mm2s_burst_size {256}] $axi_dma
  
connect_bd_net $sys_clk         [get_bd_pins $axi_dma_name/s_axi_lite_aclk]
connect_bd_net $sys_clk         [get_bd_pins $axi_dma_name/m_axi_mm2s_aclk]
connect_bd_net $sys_periph_rstn [get_bd_pins $axi_dma_name/axi_resetn]

connect_bd_intf_net [get_bd_intf_pins $axi_dma_name/M_AXIS_MM2S] [get_bd_intf_pins $axis_frame_sync_name/s_axis]

############################################################################
# AXI Interconnect - for General Purpose Interface 0
############################################################################
set axi_gp0_interconnect_name axi_interconnect_0
set axi_gp0_interconnect [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect $axi_gp0_interconnect_name]
set_property -dict [list \
    CONFIG.NUM_SI {1} \
    CONFIG.NUM_MI {2}] $axi_gp0_interconnect

connect_bd_net $sys_clk         [get_bd_pins $axi_gp0_interconnect_name/ACLK]
connect_bd_net $sys_clk         [get_bd_pins $axi_gp0_interconnect_name/S00_ACLK]
connect_bd_net $sys_clk         [get_bd_pins $axi_gp0_interconnect_name/M00_ACLK]
connect_bd_net $sys_clk         [get_bd_pins $axi_gp0_interconnect_name/M01_ACLK]
connect_bd_net $sys_interconnect_rstn [get_bd_pins $axi_gp0_interconnect_name/ARESETN]
connect_bd_net $sys_interconnect_rstn [get_bd_pins $axi_gp0_interconnect_name/S00_ARESETN]
connect_bd_net $sys_interconnect_rstn [get_bd_pins $axi_gp0_interconnect_name/M00_ARESETN]
connect_bd_net $sys_interconnect_rstn [get_bd_pins $axi_gp0_interconnect_name/M01_ARESETN]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $axi_gp0_interconnect_name/S00_AXI] [get_bd_intf_pins $sys_ps7_name/M_AXI_GP0] 
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $axi_gp0_interconnect_name/M00_AXI] [get_bd_intf_pins $axi_dma_name/S_AXI_LITE]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $axi_gp0_interconnect_name/M01_AXI] [get_bd_intf_pins $axi_af_st7735_name/s_axi_lite]

############################################################################
# AXI Interconnect - for High Performance Interface 0
############################################################################
set axi_hp0_interconnect_name axi_interconnect_1
set axi_hp0_interconnect [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect $axi_hp0_interconnect_name]
set_property -dict [list \
    CONFIG.NUM_SI {1} \
    CONFIG.NUM_MI {1}] $axi_hp0_interconnect

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $axi_hp0_interconnect_name/S00_AXI] [get_bd_intf_pins $axi_dma_name/M_AXI_MM2S]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $axi_hp0_interconnect_name/M00_AXI] [get_bd_intf_pins $sys_ps7_name/S_AXI_HP0]

connect_bd_net $sys_clk         [get_bd_pins $axi_hp0_interconnect_name/ACLK]
connect_bd_net $sys_clk         [get_bd_pins $axi_hp0_interconnect_name/S00_ACLK]
connect_bd_net $sys_clk         [get_bd_pins $axi_hp0_interconnect_name/M00_ACLK]
connect_bd_net $sys_interconnect_rstn [get_bd_pins $axi_hp0_interconnect_name/ARESETN]
connect_bd_net $sys_interconnect_rstn [get_bd_pins $axi_hp0_interconnect_name/S00_ARESETN]
connect_bd_net $sys_interconnect_rstn [get_bd_pins $axi_hp0_interconnect_name/M00_ARESETN]

############################################################################
# CPU / Memory interconnects
############################################################################
assign_bd_address -offset 0x00000000 -range 512M -target_address_space /axi_dma_0/Data_MM2S [get_bd_addr_segs sys_ps7_0/S_AXI_HP0/HP0_DDR_LOWOCM] -force

assign_bd_address -offset 0x40400000 -range 64K -target_address_space /sys_ps7_0/Data [get_bd_addr_segs axi_dma_0/S_AXI_LITE/Reg] -force
assign_bd_address -offset 0x43C00000 -range 64K -target_address_space /sys_ps7_0/Data [get_bd_addr_segs axi_af_st7735_0/s_axi_lite/reg0] -force

############################################################################
# Interface connections
############################################################################
connect_bd_net [get_bd_ports af_st7735_miso]      [get_bd_pins $axi_af_st7735_name/af_st7735_miso_i]
connect_bd_net [get_bd_ports af_st7735_mosi]      [get_bd_pins $axi_af_st7735_name/af_st7735_mosi_o]
connect_bd_net [get_bd_ports af_st7735_sck]       [get_bd_pins $axi_af_st7735_name/af_st7735_sck_o]
connect_bd_net [get_bd_ports af_st7735_tft_cs_n]  [get_bd_pins $axi_af_st7735_name/af_st7735_tft_cs_n_o]
connect_bd_net [get_bd_ports af_st7735_card_cs_n] [get_bd_pins $axi_af_st7735_name/af_st7735_card_cs_n_o]
connect_bd_net [get_bd_ports af_st7735_rst_n]     [get_bd_pins $axi_af_st7735_name/af_st7735_rst_n_o]
connect_bd_net [get_bd_ports af_st7735_dc]        [get_bd_pins $axi_af_st7735_name/af_st7735_dc_o]
connect_bd_net [get_bd_ports af_st7735_lite]      [get_bd_pins $axi_af_st7735_name/af_st7735_lite_o]
