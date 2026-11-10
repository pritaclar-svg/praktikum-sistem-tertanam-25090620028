library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_axi_lite_gpio is
end tb_axi_lite_gpio;

architecture Behavioral of tb_axi_lite_gpio is

    component axi_lite_gpio_v1_0 is
        Port (
            gpio_out      : out STD_LOGIC_VECTOR(15 downto 0);
            gpio_in       : in  STD_LOGIC_VECTOR(15 downto 0);
            S_AXI_ACLK    : in  STD_LOGIC;
            S_AXI_ARESETN : in  STD_LOGIC;
            S_AXI_AWADDR  : in  STD_LOGIC_VECTOR(3 downto 0);
            S_AXI_AWVALID : in  STD_LOGIC;
            S_AXI_AWREADY : out STD_LOGIC;
            S_AXI_WDATA   : in  STD_LOGIC_VECTOR(31 downto 0);
            S_AXI_WSTRB   : in  STD_LOGIC_VECTOR(3 downto 0);
            S_AXI_WVALID  : in  STD_LOGIC;
            S_AXI_WREADY  : out STD_LOGIC;
            S_AXI_BRESP   : out STD_LOGIC_VECTOR(1 downto 0);
            S_AXI_BVALID  : out STD_LOGIC;
            S_AXI_BREADY  : in  STD_LOGIC;
            S_AXI_ARADDR  : in  STD_LOGIC_VECTOR(3 downto 0);
            S_AXI_ARVALID : in  STD_LOGIC;
            S_AXI_ARREADY : out STD_LOGIC;
            S_AXI_RDATA   : out STD_LOGIC_VECTOR(31 downto 0);
            S_AXI_RRESP   : out STD_LOGIC_VECTOR(1 downto 0);
            S_AXI_RVALID  : out STD_LOGIC;
            S_AXI_RREADY  : in  STD_LOGIC
        );
    end component;

    signal clk        : std_logic := '0';
    signal reset_n    : std_logic := '0';
    signal gpio_out   : std_logic_vector(15 downto 0);
    signal gpio_in    : std_logic_vector(15 downto 0) := x"0000";

    signal awaddr     : std_logic_vector(3 downto 0) := "0000";
    signal awvalid    : std_logic := '0';
    signal awready    : std_logic;
    signal wdata      : std_logic_vector(31 downto 0) := (others => '0');
    signal wvalid     : std_logic := '0';
    signal wready     : std_logic;
    signal bready     : std_logic := '1';
    signal bvalid     : std_logic;

    signal araddr     : std_logic_vector(3 downto 0) := "0000";
    signal arvalid    : std_logic := '0';
    signal arready    : std_logic;
    signal rdata      : std_logic_vector(31 downto 0);
    signal rvalid     : std_logic;
    signal rready     : std_logic := '1';

begin

    uut: axi_lite_gpio_v1_0
        port map (
            gpio_out => gpio_out, gpio_in => gpio_in,
            S_AXI_ACLK => clk, S_AXI_ARESETN => reset_n,
            S_AXI_AWADDR => awaddr, S_AXI_AWVALID => awvalid, S_AXI_AWREADY => awready,
            S_AXI_WDATA => wdata, S_AXI_WSTRB => "1111", S_AXI_WVALID => wvalid, S_AXI_WREADY => wready,
            S_AXI_BRESP => open, S_AXI_BVALID => bvalid, S_AXI_BREADY => bready,
            S_AXI_ARADDR => araddr, S_AXI_ARVALID => arvalid, S_AXI_ARREADY => arready,
            S_AXI_RDATA => rdata, S_AXI_RRESP => open, S_AXI_RVALID => rvalid, S_AXI_RREADY => rready
        );

    -- Clock 100 MHz
    clk <= not clk after 5 ns;

    stimulus: process
    begin
        reset_n <= '0';
        wait for 40 ns;
        reset_n <= '1';
        wait for 20 ns;

        -- SIMULASI 1: Tulis data A5A5 ke reg0 (LED) via AXI Write
        awaddr  <= "0000"; -- Alamat reg0
        wdata   <= x"0000A5A5";
        awvalid <= '1';
        wvalid  <= '1';
        wait for 20 ns;
        awvalid <= '0';
        wvalid  <= '0';

        -- SIMULASI 2: Ubah Nilai Switch (gpio_in) ke FFFF
        wait for 500 ns;
        gpio_in <= x"FFFF";

        -- SIMULASI 3: Tulis data 1234 ke reg0 (LED)
        wait for 500 ns;
        awaddr  <= "0000";
        wdata   <= x"00001234";
        awvalid <= '1';
        wvalid  <= '1';
        wait for 20 ns;
        awvalid <= '0';
        wvalid  <= '0';

        wait;
    end process;

end Behavioral;