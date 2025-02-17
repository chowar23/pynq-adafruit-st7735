####################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved 
#
# File: adafruit_st77xx.py
####################################################################

class ST77XX():
    # Adafruit ST77XX commands
    NOP     = 0x00
    SWRESET = 0x01
    RDDID   = 0x04
    RDDST   = 0x09

    SLPIN   = 0x10
    SLPOUT  = 0x11
    PTLON   = 0x12
    NORON   = 0x13

    INVOFF  = 0x20
    INVON   = 0x21
    DISPOFF = 0x28
    DISPON  = 0x29
    CASET   = 0x2A
    RASET   = 0x2B
    RAMWR   = 0x2C
    RAMRD   = 0x2E

    PTLAR   = 0x30
    TEOFF   = 0x34
    TEON    = 0x35
    MADCTL  = 0x36
    COLMOD  = 0x3A

    MADCTL_MY  = 0x80
    MADCTL_MX  = 0x40
    MADCTL_MV  = 0x20
    MADCTL_ML  = 0x10
    MADCTL_RGB = 0x00

    RDID1   = 0xDA
    RDID2   = 0xDB
    RDID3   = 0xDC
    RDID4   = 0xDD

    # 16-bit RGB565 colors
    BLACK    = 0x0000
    WHITE    = 0xFFFF
    RED      = 0xF800
    GREEN    = 0x07E0
    BLUE     = 0x001F
    CYAN     = 0x07FF
    MAGENTA  = 0xF81F
    YELLOW   = 0xFFE0
    ORANGE   = 0xFC00

