library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_alu4_signed is
end entity tb_alu4_signed;

architecture Behavioral of tb_alu4_signed is
    signal a        : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal b        : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal opcode   : STD_LOGIC := '0';
    signal result   : STD_LOGIC_VECTOR(3 downto 0);
    signal overflow : STD_LOGIC;
begin
    uut: entity work.alu4_signed
        port map (a => a, b => b, opcode => opcode, result => result, overflow => overflow);

    stim_proc: process
    begin
        -- Penjumlahan Normal
        a <= "0010"; b <= "0011"; opcode <= '0'; wait for 10 ns; -- (+2) + (+3) = +5
        a <= "1110"; b <= "1101"; opcode <= '0'; wait for 10 ns; -- (-2) + (-3) = -5

        -- Penjumlahan Overflow
        a <= "0100"; b <= "0101"; opcode <= '0'; wait for 10 ns; -- (+4) + (+5) = +9 (Overflow! Hasil "1001" = -7)
        a <= "0111"; b <= "0001"; opcode <= '0'; wait for 10 ns; -- (+7) + (+1) = +8 (Overflow! Hasil "1000" = -8)
        a <= "1000"; b <= "1111"; opcode <= '0'; wait for 10 ns; -- (-8) + (-1) = -9 (Overflow! Hasil "0111" = +7)

        -- Pengurangan Normal
        a <= "0101"; b <= "0010"; opcode <= '1'; wait for 10 ns; -- (+5) - (+2) = +3
        a <= "1110"; b <= "0001"; opcode <= '1'; wait for 10 ns; -- (-2) - (+1) = -3

        -- Pengurangan Overflow
        a <= "0111"; b <= "1111"; opcode <= '1'; wait for 10 ns; -- (+7) - (-1) = +8 (Overflow! Hasil "1000" = -8)
        a <= "1000"; b <= "0001"; opcode <= '1'; wait for 10 ns; -- (-8) - (+1) = -9 (Overflow! Hasil "0111" = +7)
        a <= "1001"; b <= "0100"; opcode <= '1'; wait for 10 ns; -- (-7) - (+4) = -11 (Overflow! Hasil "0101" = +5)

        report "Simulasi Tugas 3 (ALU Signed Overflow) Selesai Berhasil!" severity note;
        wait;
    end process;
end architecture Behavioral;