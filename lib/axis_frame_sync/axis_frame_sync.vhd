----------------------------------------------------------------------------
-- Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
--
-- File Name: axis_frame_sync.vhd
-- Module Name: axis_frame_sync - Behavioral
--
-- Description: Limit AXI stream burst to desired frame rate.
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity axis_frame_sync is
  generic (
    FRAME_RATE_HZ : natural := 24;
    CLOCK_RATE_HZ : natural := 100000000
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
end axis_frame_sync;

architecture Behavioral of axis_frame_sync is

  type StateType is (
    S_IDLE,
    S_BURST,
    S_WAIT
  );

  signal state_r, state_next : StateType;
  
  signal valid_txn : std_logic;
  signal last_txn  : std_logic;
  
  constant CLKS_PER_FRAME : natural := natural(floor(real(CLOCK_RATE_HZ)/real(FRAME_RATE_HZ)));
  signal timer_r : natural range 0 to CLKS_PER_FRAME - 1;
  
  signal timer_rst  : std_logic;
  signal timer_inc  : std_logic;
  signal timer_done : std_logic;
  
begin
  ----------------------------------------------------------------------------
  -- AXI Stream signals
  ----------------------------------------------------------------------------
  m_axis_tdata <= s_axis_tdata;
  m_axis_tlast <= s_axis_tlast;
  
  m_axis_tvalid <= s_axis_tvalid when (state_r /= S_WAIT) else '0';
  s_axis_tready <= m_axis_tready when (state_r /= S_WAIT) else '0';
  
  valid_txn <= s_axis_tvalid and m_axis_tready;
  last_txn  <= valid_txn and s_axis_tlast;
  
  ----------------------------------------------------------------------------
  -- Timer stall data
  ----------------------------------------------------------------------------
  process(axis_aclk)
  begin
    if rising_edge(axis_aclk) then
      if axis_aresetn = '0' then
        timer_r <= 0;
      else
        if timer_rst = '1' then
          timer_r <= 0;
        elsif timer_inc = '1' then
          timer_r <= timer_r + 1;
        end if;
      end if;
    end if;
  end process;
  
  timer_rst  <= '1' when (timer_done = '1' and (last_txn = '1' or state_r = S_WAIT)) else '0';
  timer_inc  <= '1' when (timer_done = '0' and state_next /= S_IDLE) else '0';
  timer_done <= '1' when (timer_r = CLKS_PER_FRAME-1) else '0';
  
  ----------------------------------------------------------------------------
  -- State machine to control sending data word one bit at a time
  ----------------------------------------------------------------------------
  -- State register
  process(axis_aclk)
  begin
    if rising_edge(axis_aclk) then
      if axis_aresetn = '0' then
        state_r <= S_IDLE;
      else
        state_r <= state_next;
      end if;
    end if;
  end process;
  
  -- Next state logic
  process (state_r, valid_txn, last_txn, timer_done)
  begin
    state_next <= state_r; -- default value
    case state_r is
      -- Idle state
      when S_IDLE =>
        -- Valid transaction:
        --   Start burst
        if valid_txn = '1' then
          state_next <= S_BURST;
        end if;

      -- Data can be passed through
      when S_BURST =>
        -- Last valid transaction: 
        --   If timer is not done, then wait.
        --   Else keep bursting.
        if last_txn = '1' and timer_done = '0' then
          state_next <= S_WAIT;
        end if;
      
      -- Wait for frame timer to finish  
      when S_WAIT =>
        -- Time is done:
        --   If valid transaction, then start a burst.
        --   Else wait for valid transaction.
        if timer_done = '1' then
          if valid_txn = '1' then
            state_next <= S_BURST;
          else
            state_next <= S_IDLE;
          end if;
        end if;
        
    end case;
  end process;

end Behavioral;
