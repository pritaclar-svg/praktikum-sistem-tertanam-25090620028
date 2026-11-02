library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench versi KOMBINASIONAL (Polos) -- Prosedur Praktikum poin 1
entity tb_fixed_mul_q8_8 is
end tb_fixed_mul_q8_8;

architecture sim of tb_fixed_mul_q8_8 is
    component fixed_mul_q8_8
        Port ( a      : in  STD_LOGIC_VECTOR (15 downto 0);
               b      : in  STD_LOGIC_VECTOR (15 downto 0);
               result : out STD_LOGIC_VECTOR (15 downto 0) );
    end component;

    signal a, b, result : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
begin
    UUT: fixed_mul_q8_8 port map ( a => a, b => b, result => result );

    process
    begin
        -- 2.0 x 3.0 = 6.0  -> 0x0200 x 0x0300 = 0x0600
        a <= x"0200"; b <= x"0300"; wait for 20 ns;
        assert result = x"0600"
            report "GAGAL: 2.0 x 3.0 harus = 6.0 (0x0600)" severity error;

        -- 1.5 x 2.0 = 3.0
        a <= x"0180"; b <= x"0200"; wait for 20 ns;
        assert result = x"0300"
            report "GAGAL: 1.5 x 2.0 harus = 3.0 (0x0300)" severity error;

        -- 0.5 x 0.5 = 0.25
        a <= x"0080"; b <= x"0080"; wait for 20 ns;
        assert result = x"0040"
            report "GAGAL: 0.5 x 0.5 harus = 0.25 (0x0040)" severity error;

        -- 4.25 x 2.0 = 8.5
        a <= x"0440"; b <= x"0200"; wait for 20 ns;
        assert result = x"0880"
            report "GAGAL: 4.25 x 2.0 harus = 8.5 (0x0880)" severity error;

        report "SELESAI: jika tidak ada pesan error di atas, semua test LOLOS.";
        wait;
    end process;
end sim;