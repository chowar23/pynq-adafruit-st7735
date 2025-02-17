----------------------------------------------------------------------------
-- Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
--
-- File Name: axis_frame_sync_tb.vhd
-- Module Name: axis_frame_sync_tb - Behavioral
--
-- Description: Simulation to test AXI Stream Frame Synchronizer.
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.nand_compute_std.all;

entity axis_frame_sync_tb is
--  Port ( );
end axis_frame_sync_tb;

architecture Behavioral of axis_frame_sync_tb is

  component axis_frame_sync is
    generic (
      FRAME_RATE : natural := 24;
      CLOCK_HZ   : natural := 100000000
    );
    port (
      -- Common AXI signals
      axis_aclk     : in  std_logic;
      axis_aresetn  : in  std_logic;
      -- AXI Slave (input bus)
      s_axis_tdata  : in  std_logic_vector(7 downto 0);
      s_axis_tlast  : in  std_logic;
      s_axis_tready : out std_logic;
      s_axis_tvalid : in  std_logic;
      -- AXI Master (output bus)
      m_axis_tdata  : out std_logic_vector(7 downto 0);
      m_axis_tlast  : out std_logic;
      m_axis_tready : in  std_logic;
      m_axis_tvalid : out std_logic
    );
  end component;

  -- Configuration

  -- Clocks
  constant clk_period : time := 10 ns; -- 100 MHz clock
  signal axis_aclk : std_logic := '0';

  -- Resets
  signal axis_aresetn  : std_logic;
  
  -- AXI Stream Signals
  signal s_axis_tdata  : std_logic_vector(7 downto 0);
  signal s_axis_tlast  : std_logic;
  signal s_axis_tready : std_logic;
  signal s_axis_tvalid : std_logic;
  signal m_axis_tdata  : std_logic_vector(7 downto 0);
  signal m_axis_tlast  : std_logic;
  signal m_axis_tready : std_logic;
  signal m_axis_tvalid : std_logic;
  
begin
  -----------------------------------------------------------------------------    
  -- Clocks
  -----------------------------------------------------------------------------
  axis_aclk <= not axis_aclk after clk_period/2;
  
  -----------------------------------------------------------------------------
  -- Device under test
  -----------------------------------------------------------------------------
  dut : axis_frame_sync
  generic map(
    FRAME_RATE => 2,
    CLOCK_HZ   => 33
  )
  port map(
    -- Common AXI signals
    axis_aclk     => axis_aclk,
    axis_aresetn  => axis_aresetn,
    -- AXI Slave (input bus)
    s_axis_tdata  => s_axis_tdata,
    s_axis_tlast  => s_axis_tlast,
    s_axis_tready => s_axis_tready,
    s_axis_tvalid => s_axis_tvalid,
    -- AXI Master (output bus)
    m_axis_tdata  => m_axis_tdata,
    m_axis_tlast  => m_axis_tlast,
    m_axis_tready => m_axis_tready,
    m_axis_tvalid => m_axis_tvalid
  );

  -----------------------------------------------------------------------------
  -- Reset
  ----------------------------------------------------------------------------- 
  process begin
    axis_aresetn <= '0';

    for i in 1 to 5 loop
      wait until rising_edge(axis_aclk);
    end loop;
      
    axis_aresetn <= '1';
    wait;
  end process;
  

  -----------------------------------------------------------------------------
  -- Stimulus
  ----------------------------------------------------------------------------- 
  process begin
    -------------------------------
    -- Initialize signals
    -------------------------------
    m_axis_tready <= '0';
    s_axis_tvalid <= '0';
    s_axis_tlast  <= '0';
    s_axis_tdata <= (others=>'0');
    
    -- Wait until reset is deasserted (and next clock edge)
    wait until axis_aresetn = '1';
    wait until rising_edge(axis_aclk);
    wait until rising_edge(axis_aclk);
    
    -------------------------------
    -- Burst Data
    -------------------------------
    for i in 1 to 5 loop 
      m_axis_tready <= '1';  
      s_axis_tvalid <= '1';
      s_axis_tlast  <= '0';
      s_axis_tdata <= f_int_to_slv(i, s_axis_tdata'length);
      wait until rising_edge(axis_aclk);
    end loop;
    
    -------------------------------
    -- Send last data word
    -------------------------------
    m_axis_tready <= '1';  
    s_axis_tvalid <= '1';
    s_axis_tlast  <= '1';
    s_axis_tdata <= f_int_to_slv(6, s_axis_tdata'length);
    wait until rising_edge(axis_aclk);
    
    -------------------------------
    -- Wait on frame to finish
    -------------------------------
    m_axis_tready <= '0';  
    s_axis_tvalid <= '1';
    s_axis_tlast  <= '0';
    s_axis_tdata <= f_int_to_slv(7, s_axis_tdata'length);
    for i in 1 to 32 loop   
      wait until rising_edge(axis_aclk);
    end loop;

    -------------------------------
    -- Testing complete
    -------------------------------
    m_axis_tready <= '0';
    s_axis_tvalid <= '0';
    s_axis_tlast  <= '0';
    report "Test complete.";
    wait;
  end process;

end Behavioral;
