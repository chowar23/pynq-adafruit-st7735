####################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved 
#
# File: lcd_demo.py
####################################################################

import cv2
import numpy as np

from pynq import allocate
from pynq import Clocks
from pynq import Overlay

from adafruit_st7735 import ST7735
from pynq_spi_tft import PynqSpiTft

# Video to send to LCD Screen
VIDEO_FILE = "BigBuckBunny_640x360.m4v"

# Bit file to use
BIT_FILE = "lcd_demo_arty_z7_20.bit"

####################################################
# Load overlay from PS to PL
####################################################
overlay = Overlay(BIT_FILE)
print('Bit file loaded..')

####################################################
# Configure PL clock since we didn't change BOOT.BIN
# after generating PL bit file.
####################################################
print(f'Clock was: {Clocks.fclk0_mhz} MHz')
Clocks.fclk0_mhz = 100
print(f'Clock is:  {Clocks.fclk0_mhz} MHz')

####################################################
# Configure interface to Adafruit ST7735 TFT
####################################################
spi = PynqSpiTft()
spi.reset()
lcd = ST7735(spi, tab_color="ST7735R_BLACK_TAB")

####################################################
# Configure DMA
####################################################
dma = overlay.axi_dma_0

####################################################
# Allocate image buffer
####################################################
TX_BUFFER_SIZE = 3*lcd.width*lcd.height
tx_buffer = allocate(shape=(TX_BUFFER_SIZE,), dtype=np.uint8)

####################################################
# Open video file and check for error(s)
####################################################
vid = cv2.VideoCapture(VIDEO_FILE)
if vid.isOpened() == False: 
  print('Error opening video stream or file..')
else:
  print('Video file opened successfully..')

####################################################
# Send video to screen one image at a time
####################################################
lcd.set_rotation(3)
lcd.enable_display(True)
lcd.set_addr_window(0, 0, lcd.width, lcd.height)

print('Send video frames..')
while True:
    # Grab next video frame
    ret, frame = vid.read()
    if ret == False:
        break
    
    # Resize image to LCD screen size
    frame_128x160 = cv2.resize(frame, (lcd.width, lcd.height), interpolation=cv2.INTER_NEAREST)
    
    # Send image and wait for transfer to finish
    tx_buffer[:] = frame_128x160.flatten().view(dtype=np.uint8)
    dma.sendchannel.transfer(tx_buffer)
    dma.sendchannel.wait()    

# Clean Up
del tx_buffer
vid.release()
print('Done..')
