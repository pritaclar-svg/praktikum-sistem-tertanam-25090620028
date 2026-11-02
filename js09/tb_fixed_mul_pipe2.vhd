library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench versi PIPELINE 2 TAHAP -- Prosedur Praktikum poin 2
-- Stimulus SAMA dengan tb_fixed_mul_q8_8, tapi hasil baru muncul 2 siklus
-- clock SETELAH input diberikan -> bandingkan waveform kedua versi.
entity tb_fixed_mul_pipe2 is
end tb_fixed_mul_pipe2;

architecture sim of tb_fixed_mul_pipe2 is
    component fixed_mul_pipe2
        Port ( clk    : in  STD_LOGIC;
               a      : in  STD_LOGIC_VECTOR (15 downto 0);
               b      : in  STD_LOGIC_VECTOR (15 downto 0);
               result : out STD_LOGIC_VECTOR (15 downto 0) );
    end component;

    constant CLK_PERIOD : time := 10 ns;
    signal clk    : STD_LOGIC := '0';
    signal a, b, result : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
begin
    UUT: fixed_mul_pipe2 port map ( clk => clk, a => a, b => b, result => result );

    clk <= not clk after CLK_PERIOD/2;

    process
    begin
        wait until rising_edge(clk);
        a <= x"0200"; b <= x"0300"; -- 2.0 x 3.0 = 6.0
        wait until rising_edge(clk);
        a <= x"0180"; b <= x"0200"; -- 1.5 x 2.0 = 3.0
        wait until rising_edge(clk);
        a <= x"0080"; b <= x"0080"; -- 0.5 x 0.5 = 0.25
        wait until rising_edge(clk);
        a <= x"0440"; b <= x"0200"; -- 4.25 x 2.0 = 8.5
        wait until rising_edge(clk);

        -- latency pipeline = 2 siklus, hasil pasangan pertama muncul sekarang
        wait until rising_edge(clk);
        assert result = x"0600"
            report "GAGAL: hasil 2.0x3.0 harus = 6.0 setelah latency 2 siklus" severity error;

        wait until rising_edge(clk);
        assert result = x"0300"
            report "GAGAL: hasil 1.5x2.0 harus = 3.0" severity error;

        wait until rising_edge(clk);
        assert result = x"0040"
            report "GAGAL: hasil 0.5x0.5 harus = 0.25" severity error;

        wait until rising_edge(clk);
        assert result = x"0880"
            report "GAGAL: hasil 4.25x2.0 harus = 8.5" severity error;

        report "SELESAI: bandingkan waveform -- hasil baru muncul 2 clk setelah input.";
        wait;
    end process;
end sim;