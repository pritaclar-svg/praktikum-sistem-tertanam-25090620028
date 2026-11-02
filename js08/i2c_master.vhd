----------------------------------------------------------------------------------
-- i2c_master.vhd
-- Kerangka FSM I2C Master (pengembangan dari Kode 8.2 pada jobsheet)
-- Mode operasi: satu transaksi "write register pointer, lalu read 1 byte"
--   START -> ADDR(slave,W) -> ACK -> DATA(reg_addr) -> ACK ->
--   RSTART -> ADDR(slave,R) -> ACK -> READ(1 byte) -> NACK(master) -> STOP
--
-- Catatan: untuk transaksi WRITE-ONLY (tanpa pembacaan), gunakan sinyal
-- rw_sel = '0' sehingga FSM berhenti setelah S_DATA_ACK -> S_STOP.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_master is
    Generic ( CLK_FREQ_HZ : integer := 100_000_000;  -- clock sistem (Basys3 = 100 MHz)
              SCL_FREQ_HZ : integer := 100_000 );     -- I2C standard mode = 100 kHz
    Port ( clk        : in  STD_LOGIC;
           rst        : in  STD_LOGIC;                      -- synchronous reset, active high
           start_tx   : in  STD_LOGIC;                      -- pulsa 1 clk untuk memulai transaksi
           rw_sel     : in  STD_LOGIC;                      -- '0' = write only, '1' = write+read (repeated start)
           slave_addr : in  STD_LOGIC_VECTOR(6 downto 0);   -- alamat 7-bit slave
           reg_addr   : in  STD_LOGIC_VECTOR(7 downto 0);   -- byte yang ditulis (pointer register)
           data_rd    : out STD_LOGIC_VECTOR(7 downto 0);   -- byte hasil pembacaan
           busy       : out STD_LOGIC;                      -- '1' selama transaksi berlangsung
           done       : out STD_LOGIC;                      -- pulsa 1 clk saat transaksi selesai
           ack_error  : out STD_LOGIC;                       -- '1' jika slave tidak membalas ACK
           scl        : out STD_LOGIC;
           sda_in     : in  STD_LOGIC;                      -- level SDA dari bus (saat tri-state 'Z')
           sda_out    : out STD_LOGIC;                      -- nilai yang didrive saat sda_oe='1'
           sda_oe     : out STD_LOGIC );                    -- '1' = master mendrive SDA, '0' = lepas (Z)
end i2c_master;

architecture Behavioral of i2c_master is

    -- ===== FSM utama (mengikuti Kode 8.2, diperluas dengan state repeated start & read) =====
    type i2c_state is (S_IDLE, S_START, S_ADDR, S_ADDR_ACK,
                        S_DATA, S_DATA_ACK,
                        S_RSTART, S_ADDR_R, S_ADDR_R_ACK,
                        S_READ, S_READ_NACK, S_STOP);
    signal state : i2c_state := S_IDLE;

    -- ===== Clock divider: SCL 100 kHz dari clk sistem =====
    -- Dibagi 4 fasa per periode SCL (quarter-bit timing) agar SDA berubah
    -- saat SCL rendah dan stabil saat SCL tinggi (sesuai spesifikasi I2C).
    constant QUARTER_COUNT : integer := CLK_FREQ_HZ / (SCL_FREQ_HZ * 4);
    signal q_cnt   : integer range 0 to QUARTER_COUNT-1 := 0;
    signal quarter : unsigned(1 downto 0) := (others => '0'); -- 0,1,2,3 = fase dalam 1 bit period
    signal q_tick  : STD_LOGIC := '0';                         -- pulsa 1 clk setiap pergantian fase

    signal scl_int    : STD_LOGIC := '1';
    signal sda_int     : STD_LOGIC := '1';
    signal sda_oe_int  : STD_LOGIC := '1';

    signal bit_cnt  : integer range 0 to 7 := 0;
    signal shift_tx : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); -- byte yang sedang dikirim
    signal shift_rx : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); -- byte yang sedang diterima
    signal rw_latch : STD_LOGIC := '0';

begin

    ----------------------------------------------------------------
    -- Generator fase SCL (4 fase per bit period -> SCL 100 kHz)
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                q_cnt   <= 0;
                quarter <= (others => '0');
                q_tick  <= '0';
            elsif state = S_IDLE then
                q_cnt   <= 0;
                quarter <= (others => '0');
                q_tick  <= '0';
            else
                if q_cnt = QUARTER_COUNT-1 then
                    q_cnt   <= 0;
                    quarter <= quarter + 1;
                    q_tick  <= '1';
                else
                    q_cnt  <= q_cnt + 1;
                    q_tick <= '0';
                end if;
            end if;
        end if;
    end process;

    -- SCL: rendah pada fase 0, tinggi pada fase 1-2, turun lagi pada fase 3
    -- (pola standar: SDA berubah di fase 0, SCL naik di fase 1, data stabil
    --  dibaca/dikirim di fase 2, SCL turun di fase 3)
    scl_int <= '0' when (quarter = "00" or quarter = "11") else '1';

    ----------------------------------------------------------------
    -- FSM utama
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state      <= S_IDLE;
                busy       <= '0';
                done       <= '0';
                ack_error  <= '0';
                sda_int    <= '1';
                sda_oe_int <= '1';
                bit_cnt    <= 0;
            else
                done <= '0'; -- default, hanya '1' selama 1 siklus

                case state is

                    ----------------------------------------------------
                    when S_IDLE =>
                        busy       <= '0';
                        sda_int    <= '1';
                        sda_oe_int <= '1';
                        if start_tx = '1' then
                            busy     <= '1';
                            rw_latch <= rw_sel;
                            shift_tx <= slave_addr & '0'; -- addr(6:0) & W
                            bit_cnt  <= 0;
                            state    <= S_START;
                        end if;

                    ----------------------------------------------------
                    -- Kondisi START: SDA turun saat SCL tinggi
                    when S_START =>
                        sda_oe_int <= '1';
                        if q_tick = '1' and quarter = "00" then
                            sda_int <= '0';         -- SDA turun
                        end if;
                        if q_tick = '1' and quarter = "11" then
                            state <= S_ADDR;        -- lanjut kirim alamat setelah SCL turun
                        end if;

                    ----------------------------------------------------
                    -- Kirim 8 bit: alamat slave(7) + R/W(1)
                    when S_ADDR =>
                        sda_oe_int <= '1';
                        if q_tick = '1' and quarter = "00" then
                            sda_int <= shift_tx(7);
                        end if;
                        if q_tick = '1' and quarter = "11" then
                            if bit_cnt = 7 then
                                bit_cnt <= 0;
                                state   <= S_ADDR_ACK;
                            else
                                shift_tx <= shift_tx(6 downto 0) & '0';
                                bit_cnt  <= bit_cnt + 1;
                            end if;
                        end if;

                    ----------------------------------------------------
                    -- Lepas SDA, baca ACK dari slave
                    when S_ADDR_ACK =>
                        sda_oe_int <= '0'; -- lepas bus, biarkan slave menarik rendah untuk ACK
                        if q_tick = '1' and quarter = "10" then
                            ack_error <= sda_in; -- '1' = NACK (tidak ada slave membalas)
                        end if;
                        if q_tick = '1' and quarter = "11" then
                            shift_tx <= reg_addr;
                            state    <= S_DATA;
                        end if;

                    ----------------------------------------------------
                    -- Kirim 1 byte data (pointer register)
                    when S_DATA =>
                        sda_oe_int <= '1';
                        if q_tick = '1' and quarter = "00" then
                            sda_int <= shift_tx(7);
                        end if;
                        if q_tick = '1' and quarter = "11" then
                            if bit_cnt = 7 then
                                bit_cnt <= 0;
                                state   <= S_DATA_ACK;
                            else
                                shift_tx <= shift_tx(6 downto 0) & '0';
                                bit_cnt  <= bit_cnt + 1;
                            end if;
                        end if;

                    ----------------------------------------------------
                    when S_DATA_ACK =>
                        sda_oe_int <= '0';
                        if q_tick = '1' and quarter = "11" then
                            if rw_latch = '1' then
                                state <= S_RSTART;     -- lanjut repeated start untuk fase baca
                            else
                                state <= S_STOP;        -- transaksi write-only selesai
                            end if;
                        end if;

                    ----------------------------------------------------
                    -- Repeated START
                    when S_RSTART =>
                        sda_oe_int <= '1';
                        if q_tick = '1' and quarter = "00" then
                            sda_int <= '1';
                        end if;
                        if q_tick = '1' and quarter = "01" then
                            sda_int <= '0';            -- SDA turun saat SCL tinggi -> START lagi
                        end if;
                        if q_tick = '1' and quarter = "11" then
                            shift_tx <= slave_addr & '1'; -- addr & R
                            bit_cnt  <= 0;
                            state    <= S_ADDR_R;
                        end if;

                    ----------------------------------------------------
                    when S_ADDR_R =>
                        sda_oe_int <= '1';
                        if q_tick = '1' and quarter = "00" then
                            sda_int <= shift_tx(7);
                        end if;
                        if q_tick = '1' and quarter = "11" then
                            if bit_cnt = 7 then
                                bit_cnt <= 0;
                                state   <= S_ADDR_R_ACK;
                            else
                                shift_tx <= shift_tx(6 downto 0) & '0';
                                bit_cnt  <= bit_cnt + 1;
                            end if;
                        end if;

                    ----------------------------------------------------
                    when S_ADDR_R_ACK =>
                        sda_oe_int <= '0';
                        if q_tick = '1' and quarter = "10" then
                            ack_error <= sda_in;
                        end if;
                        if q_tick = '1' and quarter = "11" then
                            state <= S_READ;
                        end if;

                    ----------------------------------------------------
                    -- Baca 1 byte dari slave
                    when S_READ =>
                        sda_oe_int <= '0'; -- lepas SDA, slave yang mendrive
                        if q_tick = '1' and quarter = "10" then
                            shift_rx <= shift_rx(6 downto 0) & sda_in;
                        end if;
                        if q_tick = '1' and quarter = "11" then
                            if bit_cnt = 7 then
                                bit_cnt <= 0;
                                state   <= S_READ_NACK;
                            else
                                bit_cnt <= bit_cnt + 1;
                            end if;
                        end if;

                    ----------------------------------------------------
                    -- Master mengirim NACK (SDA='1') tanda pembacaan selesai
                    when S_READ_NACK =>
                        sda_oe_int <= '1';
                        if q_tick = '1' and quarter = "00" then
                            sda_int <= '1';
                        end if;
                        if q_tick = '1' and quarter = "11" then
                            data_rd <= shift_rx;
                            state   <= S_STOP;
                        end if;

                    ----------------------------------------------------
                    -- Kondisi STOP: SDA naik saat SCL tinggi
                    when S_STOP =>
                        sda_oe_int <= '1';
                        if q_tick = '1' and quarter = "00" then
                            sda_int <= '0';
                        end if;
                        if q_tick = '1' and quarter = "01" then
                            sda_int <= '1';   -- SDA naik saat SCL tinggi -> STOP
                        end if;
                        if q_tick = '1' and quarter = "11" then
                            busy  <= '0';
                            done  <= '1';
                            state <= S_IDLE;
                        end if;

                    when others =>
                        state <= S_IDLE;

                end case;
            end if;
        end if;
    end process;

    scl     <= scl_int;
    sda_out <= sda_int;
    sda_oe  <= sda_oe_int;

end Behavioral;