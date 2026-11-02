library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- TUGAS PRAKTIKUM 1: versi pipeline 3 tahap dari fixed_mul_q8_8
-- Tahap 1 : hitung dua perkalian PARSIAL  -> a*b_high (bit atas b) dan a*b_low (bit bawah b)
-- Tahap 2 : JUMLAHKAN hasil parsial (dengan pergeseran) -> hasil kali penuh Q16.16
-- Tahap 3 : SCALING akhir (geser 8 bit) -> hasil Q8.8
entity fixed_mul_pipe3 is
    Port ( clk    : in  STD_LOGIC;
           a      : in  STD_LOGIC_VECTOR (15 downto 0); -- format Q8.8
           b      : in  STD_LOGIC_VECTOR (15 downto 0); -- format Q8.8
           result : out STD_LOGIC_VECTOR (15 downto 0) ); -- format Q8.8
end fixed_mul_pipe3;

architecture Behavioral of fixed_mul_pipe3 is
    -- Register tahap 1 : perkalian parsial 16x8 bit
    signal pp_high_reg : unsigned(23 downto 0); -- a * b(15 downto 8)
    signal pp_low_reg  : unsigned(23 downto 0); -- a * b(7  downto 0)

    -- Register tahap 2 : hasil kali penuh Q16.16
    signal product_reg : unsigned(31 downto 0);

    -- Register tahap 3 : hasil akhir Q8.8
    signal result_reg  : STD_LOGIC_VECTOR(15 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Tahap 1: perkalian parsial
            -- b = b_high * 256 + b_low, sehingga a*b = (a*b_high)*256 + (a*b_low)
            pp_high_reg <= unsigned(a) * unsigned(b(15 downto 8));
            pp_low_reg  <= unsigned(a) * unsigned(b(7  downto 0));

            -- Tahap 2: penjumlahan hasil parsial (pp_high digeser 8 bit ke kiri)
            product_reg <= shift_left(resize(pp_high_reg, 32), 8)
                            + resize(pp_low_reg, 32);

            -- Tahap 3: scaling, ambil kembali ke format Q8.8
            result_reg <= STD_LOGIC_VECTOR(product_reg(23 downto 8));
        end if;
    end process;

    result <= result_reg;
    -- Catatan: latency menjadi 3 siklus clock. Tiap tahap kombinasional lebih
    -- pendek dibanding versi pipe2 (perkalian 16x8 lebih ringan daripada 16x16),
    -- sehingga fmax yang dicapai berpotensi lebih tinggi lagi, dengan
    -- konsekuensi jumlah flip-flop (resource) yang dipakai juga bertambah.
end Behavioral;