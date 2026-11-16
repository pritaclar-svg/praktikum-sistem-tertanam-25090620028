----------------------------------------------------------------------------
-- JOBSHEET 11 - TUGAS PRAKTIKUM No.2 (kotak indikator SAJA)
-- File   : box_indicator_pattern.vhd
-- Fungsi : Kotak indikator berwarna merah yang posisi horizontalnya
--          mengikuti nilai sw(3:0). Semakin besar nilai switch (0-15),
--          semakin ke kanan posisi kotak. Latar belakang hitam polos
--          (tanpa pola checkerboard, itu ada di Tugas 1 /
--          checkerboard_pattern.vhd).
--
-- Perhitungan posisi kotak:
--   - Area aktif horizontal = 640 piksel, dibagi 16 posisi (sw 4-bit).
--   - Lebar tiap slot posisi = 640/16 = 40 piksel.
--   - Kotak indikator berukuran BOX_W x BOX_H, diletakkan di tengah
--     slot ke-N (N = nilai unsigned(sw)), pada baris vertikal tertentu
--     (BOX_Y hingga BOX_Y+BOX_H).
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity box_indicator_pattern is
    Generic ( BOX_W : integer := 32;   -- lebar kotak indikator
              BOX_H : integer := 32;   -- tinggi kotak indikator
              BOX_Y : integer := 420 ); -- posisi vertikal kotak indikator
    Port ( h_count : in  integer range 0 to 799;
           v_count : in  integer range 0 to 524;
           sw      : in  STD_LOGIC_VECTOR(3 downto 0);
           rgb     : out STD_LOGIC_VECTOR(11 downto 0) );
end box_indicator_pattern;

architecture Behavioral of box_indicator_pattern is

    constant H_DISPLAY : integer := 640;
    constant SLOT_W     : integer := H_DISPLAY / 16;  -- 40 piksel per slot switch

    signal sw_val     : integer range 0 to 15;
    signal box_x_start, box_x_end : integer range 0 to 799;
    signal box_on      : STD_LOGIC;

begin

    ------------------------------------------------------------------
    -- Posisi kotak indikator mengikuti nilai sw(3:0) (TUGAS 2)
    ------------------------------------------------------------------
    sw_val <= to_integer(unsigned(sw));

    -- Kotak diletakkan di tengah slot ke-sw_val, lebar BOX_W
    box_x_start <= sw_val * SLOT_W + (SLOT_W - BOX_W)/2;
    box_x_end   <= box_x_start + BOX_W;

    box_on <= '1' when (h_count >= box_x_start) and (h_count < box_x_end) and
                        (v_count >= BOX_Y) and (v_count < BOX_Y + BOX_H)
              else '0';

    ------------------------------------------------------------------
    -- Keluaran RGB: kotak indikator merah di atas latar hitam polos
    ------------------------------------------------------------------
    rgb <= "111100000000" when box_on = '1' else   -- merah: kotak indikator
           "000000000000";                          -- hitam: latar polos

end Behavioral;
