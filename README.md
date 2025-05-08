# Pynq PS-PL Code for Adafruit ST7735

## Requirements
- [PYNQ](https://github.com/Xilinx/PYNQ/) v3.0.0 or v3.0.1 [Belfast Release](https://github.com/Xilinx/PYNQ/releases)
- Vivado 2022.1
- PetaLinux 2022.1

Note: be careful not to mix and match versions of the tools.

## Build
To build the IP blocks and the project you need to run the Vivado settings script, navigate to the project directory, and then run make.
```
source /path/to/Xilinx/Vivado/2022.1/settings64.sh
cd /path/to/pynq-adafruit-st7735
make
```

After the build is complete you need to copy the following files onto the Arty SD card and rename them:
```
cp ./projects/lcd_demo/arty_z7_20/lcd_demo_arty_z7_20.runs/impl_1/system_top.bit ./lcd_demo_arty_z7_20.bit
cp ./projects/lcd_demo/arty_z7_20/lcd_demo_arty_z7_20.runs/impl_1/system_top.tcl ./lcd_demo_arty_z7_20.tcl
cp ./projects/lcd_demo/arty_z7_20/lcd_demo_arty_z7_20.gen/sources_1/bd/system/hw_handoff/system.hwh ./lcd_demo_arty_z7_20.hwh
```
