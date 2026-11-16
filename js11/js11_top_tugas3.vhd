----------------------------------------------------------------------------
-- JOBSHEET 11 - TUGAS PRAKTIKUM No.3 (Tantangan opsional)
-- File   : js11_top_tugas3.vhd
-- Fungsi : Top-level dengan mode alternatif resolusi 640x480@60Hz /
--          800x600@60Hz, dipilih lewat switch tambahan sw(4) ("mode_sel").
--
-- CATATAN PENTING (dikerjakan di Vivado):
--   1. Konfigurasikan Clocking Wizard (clk_wiz_0) dengan DUA output clock:
--        clk_out1 = 25 MHz  (untuk mode 640x480)
--        clk_out2 = 40 MHz  (untuk mode 800x600)
--      Kedua output harus actif bersamaan (centang "Enable Optional Clock
--      Outputs"), karena BUFGMUX di bawah memilih di antara keduanya
--      secara real-time (bukan reconfig di-the-fly).
--   2. BUFGMUX adalah primitif clock buffer/mux Xilinx yang memilih
--      clock bebas-glitch; cocok dipakai di sini karena pindah mode
--      hanya terjadi sesekali (oleh pengguna menekan switch), bukan
--      setiap siklus.
--   3. Setelah berganti mode, modul vga_sync_dual akan reset otomatis
--      (rst_sync terhubung ke btnC) - disarankan menekan btnC sesaat
--      setelah mengubah sw(4) agar pencacah h_count/v_count mulai
--      bersih pada parameter mode yang baru.
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity js11_top_tugas3 is
    Port ( clk100MHz : in  STD_LOGIC;
           btnC       : in  STD_LOGIC;
           sw         : in  STD_LOGIC_VECTOR(4 downto 0);  -- sw(3:0)=posisi kotak, sw(4)=mode_sel

           vgaRed     : out STD_LOGIC_VECTOR(3 downto 0);
           vgaGreen   : out STD_LOGIC_VECTOR(3 downto 0);
           vgaBlue    : out STD_LOGIC_VECTOR(3 downto 0);
           Hsync      : out STD_LOGIC;
           Vsync      : out STD_LOGIC );
end js11_top_tugas3;

architecture Behavioral of js11_top_tugas3 is

    component clk_wiz_0
        port ( clk_in1  : in  STD_LOGIC;
               reset    : in  STD_LOGIC;
               clk_out1 : out STD_LOGIC;  -- 25 MHz
               clk_out2 : out STD_LOGIC;  -- 40 MHz
               locked   : out STD_LOGIC );
    end component;

    component vga_sync_dual
        Port ( pclk     : in  STD_LOGIC;
               rst      : in  STD_LOGIC;
               mode_sel : in  STD_LOGIC;
               hsync    : out STD_LOGIC;
               vsync    : out STD_LOGIC;
               video_on : out STD_LOGIC;
               h_count  : out integer range 0 to 1055;
               v_count  : out integer range 0 to 627 );
    end component;

    component checkerboard_with_sw_box
        Generic ( BLOCK_SIZE_BITS : integer := 5;
                  BOX_W           : integer := 32;
                  BOX_H           : integer := 32;
                  BOX_Y           : integer := 420 );
        Port ( h_count : in  integer range 0 to 799;
               v_count : in  integer range 0 to 524;
               sw      : in  STD_LOGIC_VECTOR(3 downto 0);
               rgb     : out STD_LOGIC_VECTOR(11 downto 0) );
    end component;

    -- Primitif BUFGMUX Xilinx (pemilih clock bebas-glitch)
    component BUFGMUX
        port ( O  : out STD_LOGIC;
               I0 : in  STD_LOGIC;
               I1 : in  STD_LOGIC;
               S  : in  STD_LOGIC );
    end component;

    signal clk_25MHz, clk_40MHz : STD_LOGIC;
    signal pclk_mux             : STD_LOGIC;
    signal mmcm_locked          : STD_LOGIC;
    signal rst_sync             : STD_LOGIC;

    signal mode_sel : STD_LOGIC;

    signal video_on_i  : STD_LOGIC;
    signal h_count_i   : integer range 0 to 1055;
    signal v_count_i   : integer range 0 to 627;

    -- h_count/v_count dipotong ke rentang 0..799 / 0..524 untuk dipakai
    -- oleh pola checkerboard (area aktif maksimum 800x600 tetap > 640x480,
    -- pola otomatis "clipping" di luar 640/480 saat mode 640x480 aktif
    -- karena video_on_i sudah membatasi area tampil).
    signal h_count_clip : integer range 0 to 799;
    signal v_count_clip : integer range 0 to 524;

    signal rgb_pattern : STD_LOGIC_VECTOR(11 downto 0);
    signal rgb_out     : STD_LOGIC_VECTOR(11 downto 0);

begin

    mode_sel <= sw(4);
    rst_sync <= btnC or (not mmcm_locked);

    CLK_WIZ_INST: clk_wiz_0
        port map ( clk_in1  => clk100MHz,
                   reset    => btnC,
                   clk_out1 => clk_25MHz,
                   clk_out2 => clk_40MHz,
                   locked   => mmcm_locked );

    -- Pemilihan pixel clock sesuai mode_sel (S='0' -> I0, S='1' -> I1)
    PCLK_MUX_INST: BUFGMUX
        port map ( O  => pclk_mux,
                   I0 => clk_25MHz,
                   I1 => clk_40MHz,
                   S  => mode_sel );

    SYNC_INST: vga_sync_dual
        port map ( pclk     => pclk_mux,
                   rst      => rst_sync,
                   mode_sel => mode_sel,
                   hsync    => Hsync,
                   vsync    => Vsync,
                   video_on => video_on_i,
                   h_count  => h_count_i,
                   v_count  => v_count_i );

    -- Clipping aman untuk input pola (hanya relevan saat video_on='1',
    -- di mana h_count < 640 dan v_count < 480 pada mode 640x480;
    -- pada mode 800x600 pola checkerboard tetap valid untuk h<640 v<480
    -- dan berulang otomatis di luar itu berkat operasi mod pada pattern)
    h_count_clip <= h_count_i mod 800;
    v_count_clip <= v_count_i mod 525;

    PATTERN_INST: checkerboard_with_sw_box
        generic map ( BLOCK_SIZE_BITS => 5,
                      BOX_W           => 32,
                      BOX_H           => 32,
                      BOX_Y           => 420 )
        port map ( h_count => h_count_clip,
                   v_count => v_count_clip,
                   sw      => sw(3 downto 0),
                   rgb     => rgb_pattern );

    rgb_out <= rgb_pattern when video_on_i = '1' else (others => '0');

    vgaRed   <= rgb_out(11 downto 8);
    vgaGreen <= rgb_out(7 downto 4);
    vgaBlue  <= rgb_out(3 downto 0);

end Behavioral;
