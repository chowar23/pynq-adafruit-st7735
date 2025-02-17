####################################################################
# Copyright (C) 2024 Nand Compute LLC | All Rights Reserved 
#
# File: tft_spi_dev.py
####################################################################

from pynq import MMIO
import time

class PynqSpiTft():
  # Configuration register bit locations
  CFG_BIT_RST = 0 # Reset (active low)
  CFG_BIT_CS  = 1 # TFT / Card Chip Select
  CFG_BIT_DC  = 2 # Command / Data Select
    
  def __init__(self, base_addr=0x43C00000):
    # Constants
    self.BASE_ADDR = base_addr
    self.ADDR_RANGE = 64000

    self.REG_CONFIG  = 0x00
    self.REG_DATA    = 0x04

    # Memory Mapped IO for controlling module configuration registers
    self.mmio = MMIO(self.BASE_ADDR, self.ADDR_RANGE)

  def _bit_clr(self, data, bit):
    return data & ~(0x01 << bit)
    
  def _bit_get(self, data, bit):
    return (data >> bit) & 0x01
    
  def _bit_set(self, data, bit):
    return data | (0x01 << bit)
  
  def _bit_toggle(self, data, bit):
    return data ^ (0x01 << bit)   

  def enable_tft_cs(self):
    '''Enable TFT Chip Select Pin. (Driven by PL).'''
    data = self.mmio.read(self.REG_CONFIG)
    data = self._bit_set(data, self.CFG_BIT_CS)
    self.mmio.write(self.REG_CONFIG, data)

  def enable_card_cs(self):
    '''Enable Card Chip Select Pin. (Driven by PL).'''
    data = self.mmio.read(self.REG_CONFIG)
    data = self._bit_clr(data, self.CFG_BIT_CS)
    self.mmio.write(self.REG_CONFIG, data)

  def set_command_mode(self):
    '''Enable DC Pin as Command.'''
    data = self.mmio.read(self.REG_CONFIG)
    data = self._bit_clr(data, self.CFG_BIT_DC)
    self.mmio.write(self.REG_CONFIG, data)

  def set_data_mode(self):
    '''Set DC Pin as Data.'''
    data = self.mmio.read(self.REG_CONFIG)
    data = self._bit_set(data, self.CFG_BIT_DC)
    self.mmio.write(self.REG_CONFIG, data)

  def reset(self):
    '''Send reset pulse (active low).'''
    data = self.mmio.read(self.REG_CONFIG)

    # Reset enabled (active low)
    data = self._bit_clr(data, self.CFG_BIT_RST)
    self.mmio.write(self.REG_CONFIG, data)

    time.sleep(0.010)

    # Reset disabled (active high)
    data = self._bit_set(data, self.CFG_BIT_RST)
    self.mmio.write(self.REG_CONFIG, data)

  def write_command(self, data):
    '''Send single command word.'''
    self.set_command_mode()
    self.mmio.write(self.REG_DATA, data)
    self.set_data_mode()

  def write_data(self, data):
    '''Send single data word.'''
    self.mmio.write(self.REG_DATA, data)

