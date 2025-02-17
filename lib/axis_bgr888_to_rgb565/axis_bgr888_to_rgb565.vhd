----------------------------------------------------------------------------
-- Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
--
-- File Name: axis_bgr888_to_rgb565.vhd
-- Module Name: axis_bgr888_to_rgb565 - Behavioral
--
-- Description: Convert AXI stream 8-bit data from BGR888 to RGB565.
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity axis_bgr888_to_rgb565 is
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
end axis_bgr888_to_rgb565;

architecture Behavioral of axis_bgr888_to_rgb565 is

  -- State machine for converting BGR888 to RGB565
  type StateType is (
    S_IDLE,
    S_BLUE,
    S_GREEN,
    S_RED,
    S_SEND_LOWER
  );

  signal state_r, state_next : StateType;

  signal green_r : std_logic_vector(5 downto 0); -- Green 6
  signal blue_r  : std_logic_vector(4 downto 0); -- Blue 5
  
  signal lower_byte : std_logic_vector(7 downto 0);
  signal upper_byte : std_logic_vector(7 downto 0);

  signal s_axis_tlast_r : std_logic;
begin

  s_axis_tready <= m_axis_tready when (state_next = S_RED) else
                   '1'           when (state_next = S_BLUE or state_next = S_GREEN) else
                   '0';

  upper_byte <= s_axis_tdata(7 downto 3) & green_r(5 downto 3); -- R5 and upper three G6 bits
  lower_byte <= green_r(2 downto 0) & blue_r;                   -- Lower three G6 bits and B5

  m_axis_tdata <= upper_byte when (state_next = S_RED) else lower_byte;
  
  m_axis_tvalid <= s_axis_tvalid when (state_next = S_RED) else
                   '1'           when (state_next = S_SEND_LOWER) else
                   '0';

  m_axis_tlast <= s_axis_tlast_r when (state_next = S_SEND_LOWER) else '0';

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
  process (state_r, s_axis_tvalid, m_axis_tready)
  begin
    state_next <= state_r; -- default value
    case state_r is
      -- Idle state (wait for DMA to be ready)
      when S_IDLE =>
        if s_axis_tvalid = '1' then
          state_next <= S_BLUE;
        end if;

      -- Blue byte
      when S_BLUE =>
        if s_axis_tvalid = '1' then
          state_next <= S_GREEN;
        end if;

      -- Green byte
      when S_GREEN =>
        if s_axis_tvalid = '1' then
          state_next <= S_RED;
        end if;
      
      -- Red byte (and send upper byte)
      when S_RED =>
        if s_axis_tvalid = '1' and m_axis_tready = '1' then
          state_next <= S_SEND_LOWER;
        end if;

      -- Send lower byte
      when S_SEND_LOWER =>
        if m_axis_tready = '1' then
          if s_axis_tvalid = '1' then
            state_next <= S_BLUE;
          else
            state_next <= S_IDLE;
          end if;
        end if;

    end case;
  end process;

  ----------------------------------------------------------------------------
  -- Save B5 and G6 since we need to output R5 first
  ----------------------------------------------------------------------------
  process(axis_aclk)
  begin
    if rising_edge(axis_aclk) then
      if axis_aresetn = '0' then
        blue_r  <= (others=>'0');
        green_r <= (others=>'0');
      elsif s_axis_tvalid = '1' then
        -- Register B5
        if state_next = S_BLUE then
          blue_r <= s_axis_tdata(7 downto 3);
        end if;

        -- Register G6
        if state_next = S_GREEN then
          green_r <= s_axis_tdata(7 downto 2);
        end if; 
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- Save TLAST so that we can send it out with the lower byte
  ----------------------------------------------------------------------------
  process(axis_aclk)
  begin
    if rising_edge(axis_aclk) then
      if axis_aresetn = '0' then
        s_axis_tlast_r <= '0';
      elsif s_axis_tvalid = '1' and state_next = S_RED then
        s_axis_tlast_r <= s_axis_tlast;
      end if;
    end if;
  end process;

end Behavioral;
