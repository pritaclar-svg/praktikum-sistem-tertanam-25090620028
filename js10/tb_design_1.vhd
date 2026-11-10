library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_design_1 is
end tb_design_1;

architecture Behavioral of tb_design_1 is

    -- Deklarasi komponen sesuai 5 port di design_1_wrapper.v
    component design_1_wrapper is
        port (
            gpio_in_0  : in  STD_LOGIC_VECTOR (15 downto 0);
            gpio_out_0 : out STD_LOGIC_VECTOR (15 downto 0);
            reset      : in  STD_LOGIC;
            reset_0    : in  STD_LOGIC;
            sys_clock  : in  STD_LOGIC
        );
    end component;

    signal sys_clock  : std_logic := '0';
    signal reset      : std_logic := '1';
    signal reset_0    : std_logic := '1';
    signal gpio_in_0  : std_logic_vector(15 downto 0) := (others => '0');
    signal gpio_out_0 : std_logic_vector(15 downto 0);

    constant clock_period : time := 10 ns;

begin

    -- Instansiasi Design Wrapper
    uut: design_1_wrapper
        port map (
            gpio_in_0  => gpio_in_0,
            gpio_out_0 => gpio_out_0,
            reset      => reset,
            reset_0    => reset_0,
            sys_clock  => sys_clock
        );

    -- Clock Generator (100 MHz)
    clk_process : process
    begin
        sys_clock <= '0';
        wait for clock_period/2;
        sys_clock <= '1';
        wait for clock_period/2;
    end process;

    -- Stimulus Input
    stim_proc: process
    begin
        -- Inisialisasi Reset
        reset   <= '1';
        reset_0 <= '1';
        wait for 100 ns;

        -- Lepas Reset
        reset   <= '0';
        reset_0 <= '0';
        wait for 200 ns;

        -- Test Input Switches
        gpio_in_0 <= x"FFFF";
        wait for 500 ns;

        gpio_in_0 <= x"A5A5";
        wait for 1000 ns;

        wait;
    end process;

end Behavioral;