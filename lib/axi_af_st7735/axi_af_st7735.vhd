----------------------------------------------------------------------------
-- Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
--
-- File Name: axi_af_st7735.vhd
-- Module Name: axi_af_st7735 - Behavioral
--
-- Description: Interface to the Adafruit ST7735 TFT LCD screen (over SPI).
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_af_st7735 is
  generic (
    C_AXI_LITE_ADDR_WIDTH : natural := 16;
    C_AXI_LITE_DATA_WIDTH : natural := 32
  );
  port (
    -- Common AXI Signals
    axi_aclk    : in  std_logic;
    axi_aresetn : in  std_logic;
    -- AXI-Lite Slave Interface
    s_axi_lite_awvalid : in  std_logic;
    s_axi_lite_awready : out std_logic;
    s_axi_lite_awaddr  : in  std_logic_vector(C_AXI_LITE_ADDR_WIDTH-1 downto 0);
    s_axi_lite_awprot  : in  std_logic_vector(2 downto 0);
    s_axi_lite_wvalid  : in  std_logic;
    s_axi_lite_wready  : out std_logic;
    s_axi_lite_wdata   : in  std_logic_vector(C_AXI_LITE_DATA_WIDTH-1 downto 0);
    s_axi_lite_wstrb   : in  std_logic_vector(C_AXI_LITE_DATA_WIDTH/8-1 downto 0);
    s_axi_lite_bvalid  : out std_logic;
    s_axi_lite_bready  : in  std_logic;
    s_axi_lite_bresp   : out std_logic_vector(1 downto 0);
    s_axi_lite_arvalid : in  std_logic;
    s_axi_lite_arready : out std_logic;
    s_axi_lite_araddr  : in  std_logic_vector(C_AXI_LITE_ADDR_WIDTH-1 downto 0);
    s_axi_lite_arprot  : in  std_logic_vector(2 downto 0);
    s_axi_lite_rvalid  : out std_logic;
    s_axi_lite_rready  : in  std_logic;
    s_axi_lite_rdata   : out std_logic_vector(C_AXI_LITE_DATA_WIDTH-1 downto 0);
    s_axi_lite_rresp   : out std_logic_vector(1 downto 0);
    -- AXI Slave Interface (RGB565 Data)
    s_axis_tdata   : in  std_logic_vector(7 downto 0);
    s_axis_tlast   : in  std_logic;
    s_axis_tready  : out std_logic;
    s_axis_tvalid  : in  std_logic;
    -- Adafruit ST7735 Interface
    af_st7735_lite_o  : out std_logic;
    af_st7735_sck_o   : out std_logic;
    af_st7735_mosi_o  : out std_logic;
    af_st7735_miso_i  : in  std_logic;
    af_st7735_tft_cs_n_o  : out std_logic;
    af_st7735_card_cs_n_o : out std_logic;
    af_st7735_dc_o    : out std_logic;
    af_st7735_rst_n_o : out std_logic
  );
end axi_af_st7735;

architecture Behavioral of axi_af_st7735 is
  
  component axi_lite_registers is
    generic (
      SPI_DATA_WIDTH : natural := 8;
      C_AXI_ADDR_WIDTH : natural := 16;
      C_AXI_DATA_WIDTH : natural := 32
    );
    port (
      -- AXI-Lite Slave Interface
      s_axi_lite_aclk    :  in std_logic;
      s_axi_lite_aresetn :  in std_logic;
      s_axi_lite_awvalid :  in std_logic;
      s_axi_lite_awready : out std_logic;
      s_axi_lite_awaddr  :  in std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_lite_awprot  :  in std_logic_vector(2 downto 0);
      s_axi_lite_wvalid  :  in std_logic;
      s_axi_lite_wready  : out std_logic;
      s_axi_lite_wdata   :  in std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
      s_axi_lite_wstrb   :  in std_logic_vector(C_AXI_DATA_WIDTH/8-1 downto 0);
      s_axi_lite_bvalid  : out std_logic;
      s_axi_lite_bready  :  in std_logic;
      s_axi_lite_bresp   : out std_logic_vector(1 downto 0);
      s_axi_lite_arvalid :  in std_logic;
      s_axi_lite_arready : out std_logic;
      s_axi_lite_araddr  :  in std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_lite_arprot  :  in std_logic_vector(2 downto 0);
      s_axi_lite_rvalid  : out std_logic;
      s_axi_lite_rready  :  in std_logic;
      s_axi_lite_rdata   : out std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
      s_axi_lite_rresp   : out std_logic_vector(1 downto 0);
      -- Registers
      tft_cfg_o  : out std_logic_vector(2 downto 0);
      tft_data_o : out std_logic_vector(SPI_DATA_WIDTH-1 downto 0);
      tft_wr_en_o : out std_logic
    );  
  end component;
  
  component spi_controller
    generic (
      DATA_WIDTH : natural := 8
    );
    port (
      clk   : in std_logic;
      reset : in std_logic;
      -- PICO - Peripheral In Controller Out
      tx_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      tx_valid_i : in std_logic;
      tx_ready_o : out std_logic;
      -- POCI - Peripheral Out Controller In
      rx_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      rx_valid_o : out std_logic;
      -- SPI Interface
      spi_sck_o  : out std_logic;
      spi_pico_o : out std_logic;
      spi_poci_i : in  std_logic;
      spi_cs_n_o : out std_logic
    );
  end component;
  
  constant SPI_DATA_WIDTH : natural := 8;

  signal tft_cfg   : std_logic_vector(2 downto 0);
  signal tft_reset_n : std_logic;
  signal tft_cs_en : std_logic;
  signal tft_dc    : std_logic;
  
  signal tft_data  : std_logic_vector(SPI_DATA_WIDTH-1 downto 0);
  signal tft_wr_en : std_logic;
  
  signal spi_reset : std_logic;
  
  signal spi_tx_data   : std_logic_vector(SPI_DATA_WIDTH-1 downto 0);
  signal spi_tx_valid  : std_logic;
  signal spi_tx_ready  : std_logic;

  signal af_st7735_cs_n : std_logic;
  
begin

  ----------------------------------------------------------------------------
  -- AXI-Lite Register Interface
  ----------------------------------------------------------------------------
  axi_lite_registers_inst : axi_lite_registers
    generic map(
      SPI_DATA_WIDTH => SPI_DATA_WIDTH,
      C_AXI_ADDR_WIDTH => C_AXI_LITE_ADDR_WIDTH,
      C_AXI_DATA_WIDTH => C_AXI_LITE_DATA_WIDTH
    )
    port map(
      -- AXI-Lite Slave Interface
      s_axi_lite_aclk    => axi_aclk,
      s_axi_lite_aresetn => axi_aresetn,
      s_axi_lite_awvalid => s_axi_lite_awvalid,
      s_axi_lite_awready => s_axi_lite_awready,
      s_axi_lite_awaddr  => s_axi_lite_awaddr,
      s_axi_lite_awprot  => s_axi_lite_awprot,
      s_axi_lite_wvalid  => s_axi_lite_wvalid,
      s_axi_lite_wready  => s_axi_lite_wready,
      s_axi_lite_wdata   => s_axi_lite_wdata,
      s_axi_lite_wstrb   => s_axi_lite_wstrb,
      s_axi_lite_bvalid  => s_axi_lite_bvalid,
      s_axi_lite_bready  => s_axi_lite_bready,
      s_axi_lite_bresp   => s_axi_lite_bresp,
      s_axi_lite_arvalid => s_axi_lite_arvalid,
      s_axi_lite_arready => s_axi_lite_arready,
      s_axi_lite_araddr  => s_axi_lite_araddr,
      s_axi_lite_arprot  => s_axi_lite_arprot,
      s_axi_lite_rvalid  => s_axi_lite_rvalid,
      s_axi_lite_rready  => s_axi_lite_rready,
      s_axi_lite_rdata   => s_axi_lite_rdata,
      s_axi_lite_rresp   => s_axi_lite_rresp,
      -- Registers
      tft_cfg_o  => tft_cfg,
      tft_data_o => tft_data,
      tft_wr_en_o => tft_wr_en
    );

  tft_reset_n <= tft_cfg(0); -- Reset TFT and SPI block - default is inactive reset
  tft_cs_en   <= tft_cfg(1); -- Enable TFT CS (1) or SD Card CS (0) - default is TFT CS
  tft_dc      <= tft_cfg(2); -- Data (1) or Command (0) Select - default is Data
  
  ----------------------------------------------------------------------------
  -- SPI Controller Core
  ----------------------------------------------------------------------------
  spi_reset <= (not axi_aresetn) or (not tft_reset_n);
  
  spi_tx_data  <= tft_data when (tft_wr_en = '1') else s_axis_tdata;
  spi_tx_valid <= tft_wr_en or s_axis_tvalid;
  s_axis_tready <= spi_tx_ready;
  
  spi_controller_inst : spi_controller
    generic map (
      DATA_WIDTH => SPI_DATA_WIDTH
    )
    port map (
      clk   => axi_aclk,
      reset => spi_reset,
      -- PICO - Peripheral In Controller Out
      tx_data_i  => spi_tx_data,
      tx_valid_i => spi_tx_valid,
      tx_ready_o => spi_tx_ready,
      -- POCI - Peripheral Out Controller In
      rx_data_o  => open,
      rx_valid_o => open,
      -- SPI Interface
      spi_sck_o  => af_st7735_sck_o,
      spi_pico_o => af_st7735_mosi_o,
      spi_poci_i => af_st7735_miso_i,
      spi_cs_n_o => af_st7735_cs_n
    );

  af_st7735_tft_cs_n_o  <= af_st7735_cs_n when (tft_cs_en = '1') else '1';
  af_st7735_card_cs_n_o <= af_st7735_cs_n when (tft_cs_en = '0') else '1';

  af_st7735_rst_n_o <= tft_reset_n;
  af_st7735_dc_o <= tft_dc;

  af_st7735_lite_o <= '1'; -- always on for now

end Behavioral;
