library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi_lite_gpio_v1_0 is
    Generic (
        C_S_AXI_ADDR_WIDTH : integer := 4; -- 4 bit alamat (4 register 32-bit)
        C_S_AXI_DATA_WIDTH : integer := 32  -- Lebar data 32-bit
    );
    Port (
        -- User Port (Prosedur Kode 10.1: output LED dipetakan ke reg0)
        gpio_out      : out STD_LOGIC_VECTOR(15 downto 0);

        -- Bus Interface AXI4-Lite
        S_AXI_ACLK    : in  STD_LOGIC;
        S_AXI_ARESETN : in  STD_LOGIC;

        -- Write Address Channel
        S_AXI_AWADDR  : in  STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWVALID : in  STD_LOGIC;
        S_AXI_AWREADY : out STD_LOGIC;

        -- Write Data Channel
        S_AXI_WDATA   : in  STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB   : in  STD_LOGIC_VECTOR((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        S_AXI_WVALID  : in  STD_LOGIC;
        S_AXI_WREADY  : out STD_LOGIC;

        -- Write Response Channel
        S_AXI_BRESP   : out STD_LOGIC_VECTOR(1 downto 0);
        S_AXI_BVALID  : out STD_LOGIC;
        S_AXI_BREADY  : in  STD_LOGIC;

        -- Read Address Channel
        S_AXI_ARADDR  : in  STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARVALID : in  STD_LOGIC;
        S_AXI_ARREADY : out STD_LOGIC;

        -- Read Data Channel
        S_AXI_RDATA   : out STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP   : out STD_LOGIC_VECTOR(1 downto 0);
        S_AXI_RVALID  : out STD_LOGIC;
        S_AXI_RREADY  : in  STD_LOGIC
    );
end axi_lite_gpio_v1_0;

architecture Behavioral of axi_lite_gpio_v1_0 is

    -- Register Internal (4 x 32-bit)
    signal slv_reg0 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal slv_reg1 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal slv_reg2 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal slv_reg3 : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    -- Sinyal Kontrol Internal AXI
    signal axi_awready : std_logic := '0';
    signal axi_wready  : std_logic := '0';
    signal axi_bvalid  : std_logic := '0';
    signal axi_arready : std_logic := '0';
    signal axi_rdata   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal axi_rvalid  : std_logic := '0';

begin

    -- Sinyal Output Bus AXI
    S_AXI_AWREADY <= axi_awready;
    S_AXI_WREADY  <= axi_wready;
    S_AXI_BRESP   <= "00"; -- Respon OKAY
    S_AXI_BVALID  <= axi_bvalid;
    S_AXI_ARREADY <= axi_arready;
    S_AXI_RDATA   <= axi_rdata;
    S_AXI_RRESP   <= "00"; -- Respon OKAY
    S_AXI_RVALID  <= axi_rvalid;

    -- Pemetaan Register reg0 ke User Port LED (Sesuai Prosedur Kode 10.1)
    gpio_out <= slv_reg0(15 downto 0);

    -- Proses Tulis AXI (Write Transaction Process)
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_awready <= '0';
                axi_wready  <= '0';
                axi_bvalid  <= '0';
                slv_reg0    <= (others => '0');
                slv_reg1    <= (others => '0');
                slv_reg2    <= (others => '0');
                slv_reg3    <= (others => '0');
            else
                -- Handshake AWREADY & WREADY
                if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
                    axi_awready <= '1';
                    axi_wready  <= '1';
                else
                    axi_awready <= '0';
                    axi_wready  <= '0';
                end if;

                -- Menulis data ke Register sesuai alamat (menggunakan bit 3..2 untuk 4-byte boundary)
                if (S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and axi_awready = '1' and axi_wready = '1') then
                    case S_AXI_AWADDR(3 downto 2) is
                        when "00" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8)-1 loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg0((byte_index*8+7) downto byte_index*8) <= S_AXI_WDATA((byte_index*8+7) downto byte_index*8);
                                end if;
                            end loop;
                        when "01" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8)-1 loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg1((byte_index*8+7) downto byte_index*8) <= S_AXI_WDATA((byte_index*8+7) downto byte_index*8);
                                end if;
                            end loop;
                        when "10" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8)-1 loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg2((byte_index*8+7) downto byte_index*8) <= S_AXI_WDATA((byte_index*8+7) downto byte_index*8);
                                end if;
                            end loop;
                        when "11" =>
                            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8)-1 loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg3((byte_index*8+7) downto byte_index*8) <= S_AXI_WDATA((byte_index*8+7) downto byte_index*8);
                                end if;
                            end loop;
                        when others => null;
                    end case;
                end if;

                -- Handshake Response BVALID
                if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0') then
                    axi_bvalid <= '1';
                elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
                    axi_bvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Proses Baca AXI (Read Transaction Process)
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_arready <= '0';
                axi_rvalid  <= '0';
                axi_rdata   <= (others => '0');
            else
                if (axi_arready = '0' and S_AXI_ARVALID = '1') then
                    axi_arready <= '1';
                else
                    axi_arready <= '0';
                end if;

                if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
                    axi_rvalid <= '1';
                    case S_AXI_ARADDR(3 downto 2) is
                        when "00"   => axi_rdata <= slv_reg0;
                        when "01"   => axi_rdata <= slv_reg1;
                        when "10"   => axi_rdata <= slv_reg2;
                        when "11"   => axi_rdata <= slv_reg3;
                        when others => axi_rdata <= (others => '0');
                    end case;
                elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
                    axi_rvalid <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
