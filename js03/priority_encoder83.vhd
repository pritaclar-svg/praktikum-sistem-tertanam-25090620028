library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity priority_encoder83 is
    port (
        sw  : in  STD_LOGIC_VECTOR(7 downto 0); -- Input switch sw(7..0)
        led : out STD_LOGIC_VECTOR(3 downto 0)  -- Output led(2..0) = pos, led(3) = valid
    );
end entity priority_encoder83;

architecture Behavioral of priority_encoder83 is
begin
    process(sw)
        variable pos_v   : STD_LOGIC_VECTOR(2 downto 0);
        variable valid_v : STD_LOGIC;
    begin
        pos_v   := "000";
        valid_v := '0';

        -- Memindai bit dari indeks tertinggi (7) ke terendah (0)
        for i in 7 downto 0 loop
            if sw(i) = '1' then
                pos_v   := STD_LOGIC_VECTOR(to_unsigned(i, 3));
                valid_v := '1';
                exit; -- Hentikan loop begitu bit '1' tertinggi ditemukan
            end if;
        end loop;

        led(2 downto 0) <= pos_v;
        led(3)          <= valid_v;
    end process;
end architecture Behavioral;