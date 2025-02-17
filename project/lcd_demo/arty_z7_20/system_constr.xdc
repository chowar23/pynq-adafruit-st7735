## This file is a general .xdc for the ARTY Z7-20 Rev.B
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## ChipKit Outer Digital Header
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { af_st7735_lite  }];      #IO_L5P_T0_34            Sch=CK_IO0
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { af_st7735_miso  }];      #IO_L2N_T0_34            Sch=CK_IO1
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports { af_st7735_sck  }];       #IO_L3P_T0_DQS_PUDC_B_34 Sch=CK_IO2
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { af_st7735_mosi  }];      #IO_L3N_T0_DQS_34        Sch=CK_IO3
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { af_st7735_tft_cs_n  }];  #IO_L10P_T1_34           Sch=CK_IO4
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { af_st7735_card_cs_n  }]; #IO_L5N_T0_34            Sch=CK_IO5
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { af_st7735_dc  }];        #IO_L19P_T3_34           Sch=CK_IO6
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { af_st7735_rst_n  }];     #IO_L9N_T1_DQS_34        Sch=CK_IO7
