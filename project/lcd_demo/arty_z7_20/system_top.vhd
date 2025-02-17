----------------------------------------------------------------------------
-- Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
--
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity system_top is
  port (
    ddr_addr    : inout std_logic_vector ( 14 downto 0 );
    ddr_ba      : inout std_logic_vector ( 2 downto 0 );
    ddr_cas_n   : inout std_logic;
    ddr_ck_n    : inout std_logic;
    ddr_ck_p    : inout std_logic;
    ddr_cke     : inout std_logic;
    ddr_cs_n    : inout std_logic;
    ddr_dm      : inout std_logic_vector ( 3 downto 0 );
    ddr_dq      : inout std_logic_vector ( 31 downto 0 );
    ddr_dqs_n   : inout std_logic_vector ( 3 downto 0 );
    ddr_dqs_p   : inout std_logic_vector ( 3 downto 0 );
    ddr_odt     : inout std_logic;
    ddr_ras_n   : inout std_logic;
    ddr_reset_n : inout std_logic;
    ddr_we_n    : inout std_logic;
    fixed_io_ddr_vrn  : inout std_logic;
    fixed_io_ddr_vrp  : inout std_logic;
    fixed_io_mio      : inout std_logic_vector ( 53 downto 0 );
    fixed_io_ps_clk   : inout std_logic;
    fixed_io_ps_porb  : inout std_logic;
    fixed_io_ps_srstb : inout std_logic;
    af_st7735_miso  : in std_logic;
    af_st7735_mosi  : out std_logic;
    af_st7735_sck   : out std_logic;
    af_st7735_tft_cs_n  : out std_logic;
    af_st7735_card_cs_n : out std_logic;
    af_st7735_rst_n : out std_logic;
    af_st7735_dc    : out std_logic;
    af_st7735_lite  : out std_logic
  );
end system_top;

architecture structure of system_top is

  component system_wrapper is
    port (
      af_st7735_miso  : in std_logic;
      af_st7735_mosi  : out std_logic;
      af_st7735_sck   : out std_logic;
      af_st7735_tft_cs_n  : out std_logic;
      af_st7735_card_cs_n : out std_logic;
      af_st7735_rst_n : out std_logic;
      af_st7735_dc    : out std_logic;
      af_st7735_lite  : out std_logic;
      ddr_cas_n : inout std_logic;
      ddr_cke   : inout std_logic;
      ddr_ck_n  : inout std_logic;
      ddr_ck_p  : inout std_logic;
      ddr_cs_n  : inout std_logic;
      ddr_reset_n : inout std_logic;
      ddr_odt   : inout std_logic;
      ddr_ras_n : inout std_logic;
      ddr_we_n  : inout std_logic;
      ddr_ba    : inout std_logic_vector ( 2 downto 0 );
      ddr_addr  : inout std_logic_vector ( 14 downto 0 );
      ddr_dm    : inout std_logic_vector ( 3 downto 0 );
      ddr_dq    : inout std_logic_vector ( 31 downto 0 );
      ddr_dqs_n : inout std_logic_vector ( 3 downto 0 );
      ddr_dqs_p : inout std_logic_vector ( 3 downto 0 );
      fixed_io_mio      : inout std_logic_vector ( 53 downto 0 );
      fixed_io_ddr_vrn  : inout std_logic;
      fixed_io_ddr_vrp  : inout std_logic;
      fixed_io_ps_srstb : inout std_logic;
      fixed_io_ps_clk   : inout std_logic;
      fixed_io_ps_porb  : inout std_logic
    );
  end component system_wrapper;

begin

  system_wrapper_inst : component system_wrapper
    port map (
      ddr_addr(14 downto 0) => ddr_addr(14 downto 0),
      ddr_ba(2 downto 0) => ddr_ba(2 downto 0),
      ddr_cas_n => ddr_cas_n,
      ddr_ck_n => ddr_ck_n,
      ddr_ck_p => ddr_ck_p,
      ddr_cke => ddr_cke,
      ddr_cs_n => ddr_cs_n,
      ddr_dm(3 downto 0) => ddr_dm(3 downto 0),
      ddr_dq(31 downto 0) => ddr_dq(31 downto 0),
      ddr_dqs_n(3 downto 0) => ddr_dqs_n(3 downto 0),
      ddr_dqs_p(3 downto 0) => ddr_dqs_p(3 downto 0),
      ddr_odt => ddr_odt,
      ddr_ras_n => ddr_ras_n,
      ddr_reset_n => ddr_reset_n,
      ddr_we_n => ddr_we_n,
      fixed_io_ddr_vrn => fixed_io_ddr_vrn,
      fixed_io_ddr_vrp => fixed_io_ddr_vrp,
      fixed_io_mio(53 downto 0) => fixed_io_mio(53 downto 0),
      fixed_io_ps_clk => fixed_io_ps_clk,
      fixed_io_ps_porb => fixed_io_ps_porb,
      fixed_io_ps_srstb => fixed_io_ps_srstb,
      af_st7735_miso => af_st7735_miso,
      af_st7735_mosi => af_st7735_mosi,
      af_st7735_sck => af_st7735_sck,
      af_st7735_tft_cs_n => af_st7735_tft_cs_n,
      af_st7735_card_cs_n => af_st7735_card_cs_n,
      af_st7735_rst_n => af_st7735_rst_n,
      af_st7735_dc => af_st7735_dc,
      af_st7735_lite => af_st7735_lite
    );

end structure;
