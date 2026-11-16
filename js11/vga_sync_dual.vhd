----------------------------------------------------------------------------
-- JOBSHEET 11 - TUGAS PRAKTIKUM No.3 (Tantangan opsional)
-- File   : vga_sync_dual.vhd
-- Fungsi : Sync generator VGA dengan DUA mode resolusi yang dapat dipilih
--          lewat switch tambahan (mode_sel):
--            mode_sel = '0' -> 640x480@60Hz  (pixel clock 25 MHz)
--            mode_sel = '1' -> 800x600@60Hz  (pixel clock 40 MHz)
--
-- Parameter 800x600@60Hz (standar VESA, dihitung ulang seperti Tabel 11.1):
--   Pixel clock  ~ 40.000 MHz
--   Horizontal : Display 800, Front porch 40, Sync 128, Back porch 88, Total 1056
--   Vertical   : Display 600, Front porch  1, Sync   4, Back porch 23, Total 628
--   (Catatan: polaritas HSYNC/VSYNC untuk 800x600 adalah POSITIF,
--    berbeda dengan 640x480 yang NEGATIF - penting agar monitor sync!)
--
-- Catatan implementasi clock:
--   pclk yang masuk ke entity ini HARUS SUDAH berupa hasil pemilihan
--   (mux) antara clk_out1=25MHz dan clk_out2=40MHz dari Clocking Wizard,
--   idealnya lewat primitif BUFGMUX agar bebas glitch saat switch
--   mode_sel berubah. Lihat catatan di js11_top_tugas3.vhd.
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_sync_dual is
    Port ( pclk     : in  STD_LOGIC;   -- pixel clock, sudah dipilih sesuai mode_sel
           rst      : in  STD_LOGIC;
           mode_sel : in  STD_LOGIC;   -- '0' = 640x480@60Hz, '1' = 800x600@60Hz
           hsync    : out STD_LOGIC;
           vsync    : out STD_LOGIC;
           video_on : out STD_LOGIC;
           h_count  : out integer range 0 to 1055;
           v_count  : out integer range 0 to 627 );
end vga_sync_dual;

architecture Behavioral of vga_sync_dual is

    -- ===== Parameter 640x480@60Hz (Tabel 11.1) =====
    constant H_DISPLAY_0 : integer := 640;
    constant H_FPORCH_0  : integer := 16;
    constant H_SYNC_0    : integer := 96;
    constant H_TOTAL_0   : integer := 800;
    constant V_DISPLAY_0 : integer := 480;
    constant V_FPORCH_0  : integer := 10;
    constant V_SYNC_0    : integer := 2;
    constant V_TOTAL_0   : integer := 525;

    -- ===== Parameter 800x600@60Hz (hasil perhitungan ulang, VESA standard) =====
    constant H_DISPLAY_1 : integer := 800;
    constant H_FPORCH_1  : integer := 40;
    constant H_SYNC_1    : integer := 128;
    constant H_TOTAL_1   : integer := 1056;
    constant V_DISPLAY_1 : integer := 600;
    constant V_FPORCH_1  : integer := 1;
    constant V_SYNC_1    : integer := 4;
    constant V_TOTAL_1   : integer := 628;

    -- Parameter aktif, dipilih sesuai mode_sel
    signal H_DISPLAY, H_FPORCH, H_SYNC, H_TOTAL : integer;
    signal V_DISPLAY, V_FPORCH, V_SYNC, V_TOTAL : integer;

    signal hc, vc : integer := 0;

begin

    -- Pemilihan parameter sesuai mode
    H_DISPLAY <= H_DISPLAY_0 when mode_sel = '0' else H_DISPLAY_1;
    H_FPORCH  <= H_FPORCH_0  when mode_sel = '0' else H_FPORCH_1;
    H_SYNC    <= H_SYNC_0    when mode_sel = '0' else H_SYNC_1;
    H_TOTAL   <= H_TOTAL_0   when mode_sel = '0' else H_TOTAL_1;

    V_DISPLAY <= V_DISPLAY_0 when mode_sel = '0' else V_DISPLAY_1;
    V_FPORCH  <= V_FPORCH_0  when mode_sel = '0' else V_FPORCH_1;
    V_SYNC    <= V_SYNC_0    when mode_sel = '0' else V_SYNC_1;
    V_TOTAL   <= V_TOTAL_0   when mode_sel = '0' else V_TOTAL_1;

    -- Pencacah posisi piksel (sinkron, direset juga saat mode_sel berubah
    -- agar pencacah tidak pernah melebihi H_TOTAL/V_TOTAL mode baru)
    process(pclk)
    begin
        if rising_edge(pclk) then
            if rst = '1' then
                hc <= 0;
                vc <= 0;
            elsif hc >= H_TOTAL-1 then
                hc <= 0;
                if vc >= V_TOTAL-1 then
                    vc <= 0;
                else
                    vc <= vc + 1;
                end if;
            else
                hc <= hc + 1;
            end if;
        end if;
    end process;

    -- Polaritas HSYNC/VSYNC berbeda antar mode:
    --   640x480  -> aktif-rendah (negatif)
    --   800x600  -> aktif-tinggi (positif)
    hsync <= '0' when mode_sel = '0' and
                       (hc >= H_DISPLAY+H_FPORCH) and (hc < H_DISPLAY+H_FPORCH+H_SYNC)
             else '1' when mode_sel = '0'
             else '1' when mode_sel = '1' and
                       (hc >= H_DISPLAY+H_FPORCH) and (hc < H_DISPLAY+H_FPORCH+H_SYNC)
             else '0';

    vsync <= '0' when mode_sel = '0' and
                       (vc >= V_DISPLAY+V_FPORCH) and (vc < V_DISPLAY+V_FPORCH+V_SYNC)
             else '1' when mode_sel = '0'
             else '1' when mode_sel = '1' and
                       (vc >= V_DISPLAY+V_FPORCH) and (vc < V_DISPLAY+V_FPORCH+V_SYNC)
             else '0';

    video_on <= '1' when (hc < H_DISPLAY) and (vc < V_DISPLAY) else '0';

    h_count <= hc;
    v_count <= vc;

end Behavioral;
