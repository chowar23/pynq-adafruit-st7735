####################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved 
#
# File: adafruit_st7735.py
####################################################################

import time

from adafruit_st77xx import ST77XX

DELAY_0_MS   = 0
DELAY_10_MS  = 10e-3
DELAY_100_MS = 100e-3
DELAY_150_MS = 150e-3
DELAY_500_MS = 150e-3

class ST7735(ST77XX):
    # Adafruit ST7735 commands
    MADCTL_BGR = 0x08
    MADCTL_MH  = 0x04

    FRMCTR1    = 0xB1
    FRMCTR2    = 0xB2
    FRMCTR3    = 0xB3
    INVCTR     = 0xB4
    DISSET5    = 0xB6

    PWCTR1     = 0xC0
    PWCTR2     = 0xC1
    PWCTR3     = 0xC2
    PWCTR4     = 0xC3
    PWCTR5     = 0xC4
    VMCTR1     = 0xC5

    PWCTR6     = 0xFC

    GMCTRP1    = 0xE0
    GMCTRN1    = 0xE1

    def __init__(self, spi, tab_color="ST7735R_GREEN_TAB"):
        # Adafruit ST7735 device specific definitions
        if tab_color == "ST7735R_GREEN_TAB":
            # Constants for ST7735R 1.8" Green Tab TFT Display.
            self.ST7735_WIDTH     = 128 # 1.8" display
            self.ST7735_HEIGHT    = 160 # 1.8" display
            self.ST7735_COL_START = 2
            self.ST7735_ROW_START = 1
            self.ST7735_MADCTL    = ST7735.MADCTL_BGR
        elif tab_color == "ST7735R_GREEN_TAB_144":
            # Constants for ST7735R 1.44" Green Tab TFT Display.
            self.ST7735_WIDTH     = 128 # 1.44" display
            self.ST7735_HEIGHT    = 128 # 1.44" display
            self.ST7735_COL_START = 0
            self.ST7735_ROW_START = 0
            self.ST7735_MADCTL    = ST7735.MADCTL_BGR
        elif tab_color == "ST7735R_BLACK_TAB":
            self.ST7735_WIDTH     = 128 # 1.8" display
            self.ST7735_HEIGHT    = 160 # 1.8" display
            self.ST7735_COL_START = 0
            self.ST7735_ROW_START = 0
            self.ST7735_MADCTL    = ST77XX.MADCTL_RGB
        elif tab_color == "ST7735R_MINI_160x80":
            self.ST7735_MADCTL    = ST77XX.MADCTL_RGB

        # Num or parameters, command byte, N byte command parameters, delay in milliseconds
        ST7735_PRESET_PARAMS = [
            0x00, ST77XX.SWRESET,       DELAY_150_MS,           # 1: Software reset
            0x00, ST77XX.SLPOUT,        DELAY_500_MS,           # 2: Out of sleep mode
            0x03, ST7735.FRMCTR1, 0x01, 0x2C, 0x2D, DELAY_0_MS, # 3: Framerate ctrl - normal mode - Rate = fosc/(1x2+40) * (LINE+2C+2D)
            0x03, ST7735.FRMCTR2, 0x01, 0x2C, 0x2D, DELAY_0_MS, # 4: Framerate ctrl - idle mode - Rate = fosc/(1x2+40) * (LINE+2C+2D)
            0x06, ST7735.FRMCTR3, 0x01, 0x2C, 0x2D,             # 5: Framerate - partial mode - Dot inversion mode
                                  0x01, 0x2C, 0x2D, DELAY_0_MS, #                               Line inversion mode
            0x01, ST7735.INVCTR,  0x07, DELAY_0_MS,             # 6: Display inversion ctrl - No inversion
            0x03, ST7735.PWCTR1,  0xA2, 0x02, 0x84, DELAY_0_MS, # 7: Power control - -4.6V, AUTO mode
            0x01, ST7735.PWCTR2,  0xC5, DELAY_0_MS,             # 8: Power control - VGH25=2.4C VGSEL=-10 VGH=3 * AVDD
            0x02, ST7735.PWCTR3,  0x0A, 0x00, DELAY_0_MS,       # 9: Power control - Opamp current small, Boost frequency
            0x02, ST7735.PWCTR4,  0x8A, 0x2A, DELAY_0_MS,       # 10: Power control - BCLK/2, Opamp current small & medium low
            0x02, ST7735.PWCTR5,  0x8A, 0xEE, DELAY_0_MS,       # 11: Power control
            0x01, ST7735.VMCTR1,  0x0E, DELAY_0_MS,             # 12: Power control
            0x00, ST77XX.INVOFF,        DELAY_0_MS,             # 13: Don't invert display
            0x01, ST77XX.MADCTL,  ST77XX.MADCTL_MX | ST77XX.MADCTL_MY | self.ST7735_MADCTL, DELAY_0_MS, # 14: Mem access ctl (directions) - Row / col addr, bottom-top refresh
            0x01, ST77XX.COLMOD,  0x05, DELAY_0_MS,             # 15: set color mode - 16-bit color
            0x04, ST77XX.CASET,   0x00, self.ST7735_COL_START,
                                0x00, self.ST7735_WIDTH  + self.ST7735_COL_START - 1, DELAY_0_MS, # 1: Column addr set - XSTART = 0, XEND = 127
            0x04, ST77XX.RASET,   0x00, self.ST7735_ROW_START,
                                0x00, self.ST7735_HEIGHT + self.ST7735_ROW_START - 1, DELAY_0_MS, # 2: Row addr set - XSTART = 0, XEND = 159
            0x10, ST7735.GMCTRP1, 0x02, 0x1C, 0x07, 0x12, 0x37, 0x32, 0x29, 0x2D, # 1: Gamma Adjustments (pos. polarity)
                      0x29, 0x25, 0x2B, 0x39, 0x00, 0x01, 0x03, 0x10, DELAY_0_MS, #   (Not entirely necessary, but provides accurate colors)
            0x10, ST7735.GMCTRN1, 0x03, 0x1D, 0x07, 0x06, 0x2E, 0x2C, 0x29, 0x2D, # 2: Gamma Adjustments (neg. polarity)
                    0x2E, 0x2E, 0x37, 0x3F, 0x00, 0x00, 0x02, 0x10, DELAY_0_MS, #   (Not entirely necessary, but provides accurate colors)
            0x00, ST77XX.NORON,         DELAY_10_MS,            # 3: Normal display on
            0x00, ST77XX.DISPON,        DELAY_100_MS]           # 4: Main screen turn on

        # SPI Interface
        self.spi = spi

        # Screen configuration
        self.height    = self.ST7735_HEIGHT
        self.width     = self.ST7735_WIDTH
        self.col_start = self.ST7735_COL_START
        self.row_start = self.ST7735_ROW_START

        # Reset screen
        self.spi.reset()

        # Configure the screen with presets
        self.configure_presets(ST7735_PRESET_PARAMS)
      
    def configure_presets(self, presets):
        '''Configure screen using list of preset commands / parameters.'''
        idx = 0
        while idx < len(presets):
            # Decode number of command parameters
            param_len = presets[idx]

            # Send command (at location idx+1)
            cmd = presets[idx+1]
            self.spi.write_command(cmd)

            # Send command parameters (if there are any, starts at location idx+2)
            for i in range(param_len):
                data = presets[idx+2+i]
                self.spi.write_data(data)

            # Delay next command (if needed)
            delay_param = presets[idx+2+param_len]
            if delay_param != DELAY_0_MS:
                time.sleep(delay_param)

            # Increment i to next command preset
            idx += (3 + param_len)

    def set_rotation(self, idx):
        '''Set origin of (0,0) and orientation of TFT display.'''
        cmd_param = self.ST7735_MADCTL

        idx = idx & 0x03 # bit mask to prevent index above 3
        if idx == 0:
            cmd_param |= ST77XX.MADCTL_MX | ST77XX.MADCTL_MY
            self.height    = self.ST7735_HEIGHT
            self.width     = self.ST7735_WIDTH
            self.col_start = self.ST7735_COL_START
            self.row_start = self.ST7735_ROW_START
        elif idx == 1:
            cmd_param |= ST77XX.MADCTL_MY | ST77XX.MADCTL_MV
            self.height    = self.ST7735_WIDTH
            self.width     = self.ST7735_HEIGHT
            self.col_start = self.ST7735_ROW_START
            self.row_start = self.ST7735_COL_START
        elif idx == 2:
            self.height    = self.ST7735_HEIGHT
            self.width     = self.ST7735_WIDTH
            self.col_start = self.ST7735_COL_START
            self.row_start = self.ST7735_ROW_START
        elif idx == 3:
            cmd_param |= ST77XX.MADCTL_MX | ST77XX.MADCTL_MV
            self.height    = self.ST7735_WIDTH
            self.width     = self.ST7735_HEIGHT
            self.col_start = self.ST7735_ROW_START
            self.row_start = self.ST7735_COL_START

        self.spi.write_command(ST77XX.MADCTL)
        self.spi.write_data(cmd_param)

    def enable_display(self, enable):
        '''Turn display on / off.'''
        if enable == True:
            self.spi.write_command(ST77XX.DISPON)
        else:
            self.spi.write_command(ST77XX.DISPOFF)

    def enable_tearing(self, enable):
        '''Turn TE pin on / off.'''
        if enable == True:
            self.spi.write_command(ST77XX.TEON)
        else:
            self.spi.write_command(ST77XX.TEOFF)

    def enable_sleep(self, enable):
        '''Turn sleep mode on / off.'''
        if enable == True:
            self.spi.write_command(ST77XX.SLPIN)
        else:
            self.spi.write_command(ST77XX.SLPOUT)

    def set_addr_window(self, x, y, w, h):
        '''
        SPI displays set an address window rectangle for blitting pixels.

        Args:
        x (int): Top left corner x coordinate
        y (int): Top left corner x coordinate
        w (int): Width of window
        h (int): Height of window
        '''
        x += self.col_start
        y += self.row_start

        self.spi.write_command(ST77XX.CASET) # Column addr set
        self.spi.write_data(0)
        self.spi.write_data(x)
        self.spi.write_data(0)
        self.spi.write_data(x + w - 1)

        self.spi.write_command(ST77XX.RASET) # Row addr set
        self.spi.write_data(0)
        self.spi.write_data(y)
        self.spi.write_data(0)
        self.spi.write_data(y + h - 1)

        self.spi.write_command(ST77XX.RAMWR) # Write to RAM
