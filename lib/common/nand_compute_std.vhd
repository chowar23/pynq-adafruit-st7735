----------------------------------------------------------------------------
-- Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
--
-- File Name: nand_compute_std.vhd
--
-- Description: Package for common utility functions.
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

package nand_compute_std is
  ----------------------------------------------------------------------------
  -- Type Conversions
  ----------------------------------------------------------------------------
  function f_int_to_slv(x : integer; slv_length : integer) return std_logic_vector;

  ----------------------------------------------------------------------------
  -- Bit Width
  -- 
  ----------------------------------------------------------------------------
  function f_bit_width_range(r : positive) return positive;

end nand_compute_std;

package body nand_compute_std is
  ----------------------------------------------------------------------------
  -- Convert from integer to Standard Logic Vector (SLV)
  ----------------------------------------------------------------------------
  function f_int_to_slv(x : integer; slv_length : integer) 
    return std_logic_vector is
  begin
      return std_logic_vector(to_unsigned(x, slv_length));
  end function;

  ----------------------------------------------------------------------------
  -- Compute bit width of a positive number
  ----------------------------------------------------------------------------
  -- range = 512 (0-511), bit width = 9
  function f_bit_width_range(r : positive)
    return positive is
  begin
    return positive(ceil(log2(real(r))));
  end function;

end nand_compute_std;

