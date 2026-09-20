library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_priority_encoder83 is
end entity tb_priority_encoder83;

architecture Behavioral of tb_priority_encoder83 is
    signal sw  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal led : STD_LOGIC_VECTOR(3 downto 0);
begin
    uut: entity work.priority_encoder83
        port map (sw => sw, led => led);

    stim_proc: process
    begin
        sw <= "00000000"; wait for 10 ns; assert (led = "0000") report "Gagal Kasus 1" severity error;
        sw <= "00000001"; wait for 10 ns; assert (led = "1000") report "Gagal Kasus 2" severity error;
        sw <= "00000010"; wait for 10 ns; assert (led = "1001") report "Gagal Kasus 3" severity error;
        sw <= "00000100"; wait for 10 ns; assert (led = "1010") report "Gagal Kasus 4" severity error;
        sw <= "00001100"; wait for 10 ns; assert (led = "1011") report "Gagal Kasus 5" severity error;
        sw <= "00010100"; wait for 10 ns; assert (led = "1100") report "Gagal Kasus 6" severity error;
        sw <= "00101010"; wait for 10 ns; assert (led = "1101") report "Gagal Kasus 7" severity error;
        sw <= "01011000"; wait for 10 ns; assert (led = "1110") report "Gagal Kasus 8" severity error;
        sw <= "10000000"; wait for 10 ns; assert (led = "1111") report "Gagal Kasus 9" severity error;
        sw <= "11111111"; wait for 10 ns; assert (led = "1111") report "Gagal Kasus 10" severity error;

        report "Simulasi Tugas 2 (Priority Encoder) Selesai Berhasil!" severity note;
        wait;
    end process;
end architecture Behavioral;