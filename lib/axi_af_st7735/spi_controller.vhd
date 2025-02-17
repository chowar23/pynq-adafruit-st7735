----------------------------------------------------------------------------
-- Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
--
-- File Name: spi_controller.vhd
-- Module Name: spi_controller - Behavioral
--
-- Description: Serial Peripheral Interface (SPI) Controller.
--
--   SCK: Serial Clock
--   PICO: Peripheral In Controller Out (MOSI)
--   POCI: Peripheral Out Controller In (MISO)
--   CS_N: Chip Select (active low)
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.nand_compute_std.all;

entity spi_controller is
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
end spi_controller;

architecture Behavioral of spi_controller is
  
  -- State machine to control data transfer
  type StateType is (
    S_IDLE,
    S_TRANSFER,
    S_LAST
  );
  signal state_r, state_next : StateType;
  
  -- Bit timer for data transfer
  constant BIT_CNT_WIDTH : integer := f_bit_width_range(DATA_WIDTH);
  constant MAX_BIT_CNT : unsigned(BIT_CNT_WIDTH-1 downto 0) := to_unsigned(DATA_WIDTH-1, BIT_CNT_WIDTH);
  signal bit_cnt_r : unsigned(BIT_CNT_WIDTH-1 downto 0);
  
  -- SPI Serial Clock
  signal spi_sck_r, spi_sck_next : std_logic;
  signal leading_edge, trailing_edge : std_logic;
  
  -- SPI Chip Select
  signal spi_cs_n_r : std_logic;
  
  -- Tx Data (PICO)
  signal tx_ready : std_logic;
  signal tx_data_r : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal tx_data_set : std_logic;
  
  -- Rx Data (POCI)
  signal rx_data_r : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal rx_valid_r : std_logic;

begin
  ----------------------------------------------------------------------------
  -- State machine to control sending data word one bit at a time
  ----------------------------------------------------------------------------
  -- State register
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state_r <= S_IDLE;
      else
        state_r <= state_next;
      end if;
    end if;
  end process;
  
  -- Next state logic
  process (state_r, tx_valid_i, bit_cnt_r)
  begin
    state_next <= state_r; -- default value
    case state_r is
      -- Idle state
      when S_IDLE =>
        if tx_valid_i = '1' then
          state_next <= S_TRANSFER;
        end if;

      -- Data transfer
      when S_TRANSFER =>
        if bit_cnt_r = MAX_BIT_CNT then
          state_next <= S_LAST;
        end if;
      
      -- Transfer finished
      when S_LAST =>
        if tx_valid_i = '1' then
          state_next <= S_TRANSFER;
        else
          state_next <= S_IDLE;
        end if;  

      -- Others
      when others =>
        state_next <= S_IDLE;
    end case;
  end process;
  
  ----------------------------------------------------------------------------
  -- Timer for counting # of bits being transferred, decrement when shifting data.
  ----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' or tx_data_set = '1' then
        bit_cnt_r <= (others=>'0');
      elsif trailing_edge = '1' then
        bit_cnt_r <= bit_cnt_r + 1;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- SPI Serial Clock
  ----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        spi_sck_r <= '0';
      else
        spi_sck_r <= spi_sck_next;
      end if;
    end if;
  end process;
  
  spi_sck_next <= '0' when (state_r = S_IDLE) else not spi_sck_r;
  
  -- Define when a leading and trailing edge occurs
  leading_edge  <= '1' when (state_r = S_TRANSFER and spi_sck_r = '0') else '0';
  trailing_edge <= '1' when (state_r = S_TRANSFER and spi_sck_r = '1') else '0';

  -- Output Serial Clock
  spi_sck_o <= spi_sck_r;
  
  ----------------------------------------------------------------------------
  -- PICO Logic (Peripheral In Controller Out)
  --   - Send MSB first
  ----------------------------------------------------------------------------
  tx_ready <= '1' when (state_r = S_IDLE or state_r = S_LAST) else '0';
  tx_ready_o <= tx_ready;
  
  tx_data_set <= tx_valid_i and tx_ready;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        tx_data_r <= (others=>'0');
      elsif tx_data_set = '1' then
        tx_data_r <= tx_data_i;
      elsif trailing_edge = '1' then
        tx_data_r <= tx_data_r(tx_data_r'high-1 downto 0) & '0';
      end if;
    end if;
  end process;

  -- Output PICO Data (sends MSB first)
  spi_pico_o <= tx_data_r(tx_data_r'high) when (spi_cs_n_r = '0') else '0';
  
  ----------------------------------------------------------------------------
  -- POCI Logic (Peripheral Out Controller In)
  --  - Receive MSB first
  ----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        rx_data_r <= (others=>'0');
        rx_valid_r <= '0';
      else
        if leading_edge = '1' then
          rx_data_r <= rx_data_r(rx_data_r'high-1 downto 0) & spi_poci_i;
        end if;
        
        rx_valid_r <= '0';
        if state_r = S_LAST then 
          rx_valid_r <= '1';
        end if;
      end if;
    end if;
  end process;
  
  -- Output received data
  rx_data_o <= rx_data_r;
  rx_valid_o <= rx_valid_r;
  
  ----------------------------------------------------------------------------
  -- SPI Chip Select (active low)
  ----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        spi_cs_n_r <= '1';
      else
        -- Note: tx_data_set = '1' has priority over state_r = S_IDLE
        if tx_data_set = '1' then
          spi_cs_n_r <= '0';
        elsif state_r = S_IDLE then
          spi_cs_n_r <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Output Chip Select (active low)
  spi_cs_n_o <= spi_cs_n_r;

end Behavioral;
