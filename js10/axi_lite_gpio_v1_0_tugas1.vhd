library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi_lite_gpio_v1_0 is
  Generic (
    C_S_AXI_ADDR_WIDTH : integer := 4;  -- 4 register -> 4 alamat (2 bit index + 2 bit byte)
    C_S_AXI_DATA_WIDTH : integer := 32
  );
  Port (
    S_AXI_ACLK    : in  STD_LOGIC;
    S_AXI_ARESETN : in  STD_LOGIC;
    S_AXI_AWADDR  : in  STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID : in  STD_LOGIC;
    S_AXI_AWREADY : out STD_LOGIC;
    S_AXI_WDATA   : in  STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WVALID  : in  STD_LOGIC;
    S_AXI_WREADY  : out STD_LOGIC;
    S_AXI_BRESP   : out STD_LOGIC_VECTOR(1 downto 0);
    S_AXI_BVALID  : out STD_LOGIC;
    S_AXI_BREADY  : in  STD_LOGIC;
    S_AXI_ARADDR  : in  STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID : in  STD_LOGIC;
    S_AXI_ARREADY : out STD_LOGIC;
    S_AXI_RDATA   : out STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP   : out STD_LOGIC_VECTOR(1 downto 0);
    S_AXI_RVALID  : out STD_LOGIC;
    S_AXI_RREADY  : in  STD_LOGIC;

    gpio_out : out STD_LOGIC_VECTOR(15 downto 0);  -- reg0 -> LED
    sw       : in  STD_LOGIC_VECTOR(15 downto 0)   -- switch -> reg1
  );
end axi_lite_gpio_v1_0;

architecture arch_imp of axi_lite_gpio_v1_0 is

  signal axi_awaddr  : STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_awready : STD_LOGIC := '0';
  signal axi_wready  : STD_LOGIC := '0';
  signal axi_bresp   : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
  signal axi_bvalid  : STD_LOGIC := '0';
  signal axi_araddr  : STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_arready : STD_LOGIC := '0';
  signal axi_rdata   : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal axi_rresp   : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
  signal axi_rvalid  : STD_LOGIC := '0';

  type reg_array is array (0 to 3) of STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal regs : reg_array := (others => (others => '0'));

  constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32) + 1; -- =2
  constant OPT_WIDTH : integer := 2; -- index 2 bit -> 4 register

begin

  S_AXI_AWREADY <= axi_awready;
  S_AXI_WREADY  <= axi_wready;
  S_AXI_BRESP   <= axi_bresp;
  S_AXI_BVALID  <= axi_bvalid;
  S_AXI_ARREADY <= axi_arready;
  S_AXI_RDATA   <= axi_rdata;
  S_AXI_RRESP   <= axi_rresp;
  S_AXI_RVALID  <= axi_rvalid;

  -- WRITE ADDRESS CHANNEL
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_awready <= '0';
        axi_awaddr  <= (others => '0');
      else
        if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
          axi_awready <= '1';
          axi_awaddr  <= S_AXI_AWADDR;
        else
          axi_awready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- WRITE DATA CHANNEL + REGISTER WRITE
  process (S_AXI_ACLK)
    variable idx : integer range 0 to 3;
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_wready <= '0';
        regs <= (others => (others => '0'));
      else
        if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
          axi_wready <= '1';
          idx := to_integer(unsigned(S_AXI_AWADDR(ADDR_LSB+OPT_WIDTH-1 downto ADDR_LSB)));
          if idx /= 1 then
            regs(idx) <= S_AXI_WDATA;
          end if;
        else
          axi_wready <= '0';
        end if;
        regs(1) <= (C_S_AXI_DATA_WIDTH-1 downto 16 => '0') & sw;
      end if;
    end if;
  end process;

  -- WRITE RESPONSE CHANNEL
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_bvalid <= '0';
        axi_bresp  <= (others => '0');
      else
        if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1'
            and S_AXI_WVALID = '1' and axi_bvalid = '0') then
          axi_bvalid <= '1';
          axi_bresp  <= "00";
        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
          axi_bvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  -- READ ADDRESS CHANNEL
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_arready <= '0';
        axi_araddr  <= (others => '1');
      else
        if (axi_arready = '0' and S_AXI_ARVALID = '1') then
          axi_arready <= '1';
          axi_araddr  <= S_AXI_ARADDR;
        else
          axi_arready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- READ DATA CHANNEL
  process (S_AXI_ACLK)
    variable idx : integer range 0 to 3;
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_rvalid <= '0';
        axi_rresp  <= (others => '0');
      else
        if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
          axi_rvalid <= '1';
          axi_rresp  <= "00";
          idx := to_integer(unsigned(axi_araddr(ADDR_LSB+OPT_WIDTH-1 downto ADDR_LSB)));
          axi_rdata <= regs(idx);
        elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
          axi_rvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  gpio_out <= regs(0)(15 downto 0);

end arch_imp;