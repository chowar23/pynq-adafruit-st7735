----------------------------------------------------------------------------
-- Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
--
-- File Name: rgb888_to_rgb565.vhd
-- Module Name: rgb888_to_rgb565 - Behavioral
--
-- Description: Convert RGB888 data into RGB565 data. (Red is MSB, Blue is LSB).
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity rgb888_to_rgb565 is
  port (
    data_i : in  std_logic_vector(23 downto 0);
    data_o : out std_logic_vector(15 downto 0)
  );
end rgb888_to_rgb565;

architecture Behavioral of rgb888_to_rgb565 is

  signal r : std_logic_vector(7 downto 0);
  signal g : std_logic_vector(7 downto 0);
  signal b : std_logic_vector(7 downto 0);

begin

  r <= data_i(23 downto 16);
  g <= data_i(15 downto 8);
  b <= data_i(7 downto 0); 

  data_o <= r(7 downto 3) & g(7 downto 2) & b(7 downto 3);

end Behavioral;
