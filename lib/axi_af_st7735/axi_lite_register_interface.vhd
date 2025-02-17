----------------------------------------------------------------------------
-- Copyright (C) 2024 Nand Compute LLC | All Rights Reserved
--
-- File Name: axi_lite_register_interface.vhd
-- Module Name: axi_lite_register_interface - Behavioral
--
-- Description: AXI-Lite Memory Mapped Interface
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.nand_compute_std.all;

entity axi_lite_registers is
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
end axi_lite_registers;

architecture Behavioral of axi_lite_registers is

  ----------------------------------------------------------------------------
  -- Constants
  ----------------------------------------------------------------------------
  constant ADDRLSB : integer := f_bit_width_range(C_AXI_DATA_WIDTH) - 3;
  
  constant RESP_OKAY   : std_logic_vector(1 downto 0) := "00";
  constant RESP_EXOKAY : std_logic_vector(1 downto 0) := "01";
  constant RESP_SLVERR : std_logic_vector(1 downto 0) := "10";
  constant RESP_DECERR : std_logic_vector(1 downto 0) := "11";

  ----------------------------------------------------------------------------
  -- Signals
  ----------------------------------------------------------------------------
  signal axi_lite_wr_valid : std_logic;
  signal axi_lite_wr_ready : std_logic;
  signal axi_lite_wr_en    : std_logic;
  signal axi_lite_wr_addr  : std_logic_vector(C_AXI_ADDR_WIDTH-ADDRLSB-1 downto 0);
  signal axi_lite_wr_data  : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
  signal axi_lite_wr_strb  : std_logic_vector(C_AXI_DATA_WIDTH/8-1 downto 0);
   
  signal axi_lite_rd_ready : std_logic;
  signal axi_lite_rd_en    : std_logic;
  signal axi_lite_rd_addr  : std_logic_vector(C_AXI_ADDR_WIDTH-ADDRLSB-1 downto 0);
  signal axi_lite_rd_data  : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
  
  signal axi_lite_rvalid  : std_logic;
  signal axi_lite_arready : std_logic;
  
  signal axi_lite_bvalid : std_logic;
  signal axi_lite_bstall : std_logic;
  
  -- Registers
  signal tft_cfg_r  : std_logic_vector(2 downto 0);
  signal tft_data_r : std_logic_vector(SPI_DATA_WIDTH-1 downto 0);
  signal tft_wr_en_r : std_logic;

begin

  ----------------------------------------------------------------------------------
  -- AXI-Lite Write Signal Logic
  ----------------------------------------------------------------------------------
  axi_lite_wr_valid <= s_axi_lite_wvalid and s_axi_lite_awvalid;   -- data valid and address valid
  axi_lite_bstall   <= axi_lite_bvalid and not(s_axi_lite_bready); -- awaiting response (BVALID=1 but BREADY=0)
  
  process(s_axi_lite_aclk)
  begin
    if rising_edge(s_axi_lite_aclk) then
      if s_axi_lite_aresetn = '0' then
        axi_lite_wr_ready <= '0';
      elsif axi_lite_wr_valid = '1' and axi_lite_wr_ready = '0' and axi_lite_bstall = '0' then
        axi_lite_wr_ready <= '1';
      else
        axi_lite_wr_ready <= '0';
      end if;
    end if;
  end process;
  
  s_axi_lite_awready <= axi_lite_wr_ready;
  s_axi_lite_wready  <= axi_lite_wr_ready;
  
  process(s_axi_lite_aclk)
  begin
    if rising_edge(s_axi_lite_aclk) then
      if s_axi_lite_aresetn = '0' then
        axi_lite_bvalid <= '0';
      elsif axi_lite_wr_ready = '1' then
        axi_lite_bvalid <= '1'; -- assert after successfull write
      elsif s_axi_lite_bready = '1' then
        axi_lite_bvalid <= '0'; -- deassert when s_axi_lite_bready && s_axi_lite_bvalid
      end if;
    end if;
  end process;
  
  s_axi_lite_bvalid <= axi_lite_bvalid;
  s_axi_lite_bresp  <= RESP_OKAY;

  ----------------------------------------------------------------------------------
  -- AXI-Lite Read Signal Logic
  ----------------------------------------------------------------------------------
  process(s_axi_lite_aclk)
  begin
    if rising_edge(s_axi_lite_aclk) then
      if s_axi_lite_aresetn = '0' then
        axi_lite_rvalid <= '0';
      elsif axi_lite_rd_ready = '1' then
        axi_lite_rvalid <= '1';
      elsif s_axi_lite_rready = '1' then
        axi_lite_rvalid <= '0';
      end if;
    end  if;
  end process;
  
  axi_lite_arready  <= not axi_lite_rvalid;
  axi_lite_rd_ready <= s_axi_lite_arvalid and axi_lite_arready;

  s_axi_lite_arready <= axi_lite_arready;
  s_axi_lite_rvalid  <= axi_lite_rvalid;
  s_axi_lite_rresp   <= RESP_OKAY;

  ----------------------------------------------------------------------------------
  -- AXI-Lite Register Logic
  -- TODO: add strobe logic
  ----------------------------------------------------------------------------------
  axi_lite_wr_addr <= s_axi_lite_awaddr(C_AXI_ADDR_WIDTH-1 downto ADDRLSB);
  axi_lite_wr_data <= s_axi_lite_wdata;
  axi_lite_wr_en   <= axi_lite_wr_ready;
  
  axi_lite_rd_addr <= s_axi_lite_araddr(C_AXI_ADDR_WIDTH-1 downto ADDRLSB);
  axi_lite_rd_en   <= not(axi_lite_rvalid) or s_axi_lite_rready;
  
  s_axi_lite_rdata <= axi_lite_rd_data; 
   
  -- Register write
  process(s_axi_lite_aclk) 
  begin
    if rising_edge(s_axi_lite_aclk) then
      if s_axi_lite_aresetn = '0' then
        tft_cfg_r  <= (others=>'1');
        tft_data_r <= (others=>'0'); 
        tft_wr_en_r <= '0';
      else
        -- Defaults
        tft_wr_en_r <= '0';
        
        -- Register updates
        if axi_lite_wr_en = '1' then
          case axi_lite_wr_addr is
            when "00" & x"000" =>
              tft_cfg_r <= axi_lite_wr_data(2 downto 0);
            when "00" & x"001" =>
              tft_data_r <= axi_lite_wr_data(SPI_DATA_WIDTH-1 downto 0);
              tft_wr_en_r <= '1';
            when others=>
          end case;
        end if;
        
      end if;
    end if;
  end process;

  tft_cfg_o  <= tft_cfg_r;
  tft_data_o <= tft_data_r;
  tft_wr_en_o <= tft_wr_en_r;

  -- Register read
  process(s_axi_lite_aclk) 
  begin
    if rising_edge(s_axi_lite_aclk) then
      if s_axi_lite_aresetn = '0' then
        axi_lite_rd_data <= (others=>'0');
      elsif axi_lite_rd_en = '1' then
        case axi_lite_rd_addr is
          when "00" & x"000" =>
            axi_lite_rd_data <= (C_AXI_DATA_WIDTH-1 downto 3 => '0') & tft_cfg_r;
          when others =>
            axi_lite_rd_data <= x"deadbeef";
        end case;
      end if;
    end if;
  end process;

end Behavioral;
