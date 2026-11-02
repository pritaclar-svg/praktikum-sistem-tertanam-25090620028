library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_bram_256x8 is
end tb_bram_256x8;

architecture sim of tb_bram_256x8 is

    component bram_256x8
        Port ( clk  : in  STD_LOGIC;
               we   : in  STD_LOGIC;
               addr : in  STD_LOGIC_VECTOR (7 downto 0);
               din  : in  STD_LOGIC_VECTOR (7 downto 0);
               dout : out STD_LOGIC_VECTOR (7 downto 0) );
    end component;

    signal clk  : STD_LOGIC := '0';
    signal we   : STD_LOGIC := '0';
    signal addr : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal din  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal dout : STD_LOGIC_VECTOR(7 downto 0);

    constant CLK_PERIOD : time := 10 ns; -- 100 MHz

    -- data uji: beberapa pasangan (alamat, data)
    type pair_array is array (0 to 4) of integer;
    constant test_addr : pair_array := (0, 1, 15, 128, 255);
    constant test_data : pair_array := (16#AA#, 16#55#, 16#0F#, 16#3C#, 16#99#);

begin

    uut: bram_256x8
        port map ( clk  => clk,
                    we   => we,
                    addr => addr,
                    din  => din,
                    dout => dout );

    -- clock generator
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    stim_proc: process
    begin
        wait for CLK_PERIOD*2;

        -- ===== tahap tulis =====
        we <= '1';
        for i in 0 to 4 loop
            addr <= std_logic_vector(to_unsigned(test_addr(i), 8));
            din  <= std_logic_vector(to_unsigned(test_data(i), 8));
            wait until rising_edge(clk);
        end loop;
        we <= '0';

        wait until rising_edge(clk);

        -- ===== tahap baca & verifikasi =====
        for i in 0 to 4 loop
            addr <= std_logic_vector(to_unsigned(test_addr(i), 8));
            wait until rising_edge(clk);  -- alamat disampel
            wait until rising_edge(clk);  -- dout_reg ter-update (1 siklus latency)

            assert (dout = std_logic_vector(to_unsigned(test_data(i), 8)))
                report "GAGAL pada alamat " & integer'image(test_addr(i)) &
                       " : data dibaca = " & integer'image(to_integer(unsigned(dout))) &
                       " , seharusnya = " & integer'image(test_data(i))
                severity error;

            if (dout = std_logic_vector(to_unsigned(test_data(i), 8))) then
                report "OK: alamat " & integer'image(test_addr(i)) &
                       " -> data = " & integer'image(to_integer(unsigned(dout)));
            end if;
        end loop;

        report "===== Simulasi selesai =====";
        wait;
    end process;

end sim;