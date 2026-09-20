library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu4_signed is
    port (
        a        : in  STD_LOGIC_VECTOR(3 downto 0);
        b        : in  STD_LOGIC_VECTOR(3 downto 0);
        opcode   : in  STD_LOGIC;                    -- '0' = tambah, '1' = kurang
        result   : out STD_LOGIC_VECTOR(3 downto 0);
        overflow : out STD_LOGIC                     -- Flag overflow
    );
end entity alu4_signed;

architecture Behavioral of alu4_signed is
begin
    process(a, b, opcode)
        variable a_s, b_s   : signed(3 downto 0);
        variable res_s      : signed(3 downto 0);
        variable ovf_v      : STD_LOGIC;
    begin
        a_s   := signed(a);
        b_s   := signed(b);
        ovf_v := '0';

        if opcode = '0' then -- Penjumlahan
            res_s := a_s + b_s;
            -- Overflow terjadi jika 2 bil positif menghasilkan negatif, atau 2 bil negatif menghasilkan positif
            if (a_s(3) = b_s(3)) and (res_s(3) /= a_s(3)) then
                ovf_v := '1';
            end if;
        else -- Pengurangan
            res_s := a_s - b_s;
            -- Overflow terjadi jika A & B beda tanda, dan tanda hasil beda dari A
            if (a_s(3) /= b_s(3)) and (res_s(3) /= a_s(3)) then
                ovf_v := '1';
            end if;
        end if;

        result   <= STD_LOGIC_VECTOR(res_s);
        overflow <= ovf_v;
    end process;
end architecture Behavioral;