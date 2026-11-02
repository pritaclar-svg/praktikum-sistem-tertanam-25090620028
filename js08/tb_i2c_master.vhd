----------------------------------------------------------------------------------
-- tb_i2c_master.vhd
-- Memicu 1 transaksi: tulis reg_addr ke slave, lalu baca 1 byte (repeated start).
-- Dilengkapi model slave I2C sederhana (behavioral) agar ACK dan data byte
-- dapat diamati pada waveform, sesuai Prosedur Praktikum langkah 4.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_i2c_master is
end tb_i2c_master;

architecture sim of tb_i2c_master is

    component i2c_master
        Generic ( CLK_FREQ_HZ : integer := 100_000_000;
                  SCL_FREQ_HZ : integer := 100_000 );
        Port ( clk        : in  STD_LOGIC;
               rst        : in  STD_LOGIC;
               start_tx   : in  STD_LOGIC;
               rw_sel     : in  STD_LOGIC;
               slave_addr : in  STD_LOGIC_VECTOR(6 downto 0);
               reg_addr   : in  STD_LOGIC_VECTOR(7 downto 0);
               data_rd    : out STD_LOGIC_VECTOR(7 downto 0);
               busy       : out STD_LOGIC;
               done       : out STD_LOGIC;
               ack_error  : out STD_LOGIC;
               scl        : out STD_LOGIC;
               sda_in     : in  STD_LOGIC;
               sda_out    : out STD_LOGIC;
               sda_oe     : out STD_LOGIC );
    end component;

    -- gunakan periode clock lebih kecil (bukan 100MHz asli) supaya simulasi cepat;
    -- CLK_FREQ_HZ di-set agar tetap menghasilkan SCL yg mudah diamati di waveform
    constant CLK_FREQ_HZ : integer := 1_000_000;  -- 1 MHz (hanya untuk simulasi)
    constant SCL_FREQ_HZ : integer := 100_000;     -- tetap 100 kHz standard mode
    constant CLK_PERIOD  : time := 1000 ns;         -- sesuai 1 MHz

    signal clk        : STD_LOGIC := '0';
    signal rst         : STD_LOGIC := '1';
    signal start_tx    : STD_LOGIC := '0';
    signal rw_sel      : STD_LOGIC := '1'; -- write lalu read (repeated start)
    signal slave_addr  : STD_LOGIC_VECTOR(6 downto 0) := "1001000"; -- contoh: 0x48 (mirip ADT7420)
    signal reg_addr    : STD_LOGIC_VECTOR(7 downto 0) := x"00";     -- pointer register suhu
    signal data_rd     : STD_LOGIC_VECTOR(7 downto 0);
    signal busy, done, ack_error : STD_LOGIC;

    signal scl         : STD_LOGIC;
    signal sda_in       : STD_LOGIC;
    signal sda_out      : STD_LOGIC;
    signal sda_oe        : STD_LOGIC;

    -- bus SDA fisik (open-drain, pull-up logika via resolved std_logic + 'H')
    signal sda_bus : STD_LOGIC;

    -- sinyal kendali dari model slave
    signal slave_drive : STD_LOGIC := 'Z';

    constant SLAVE_READ_BYTE : STD_LOGIC_VECTOR(7 downto 0) := x"5A"; -- data dummy dibalas slave

begin

    uut: i2c_master
        generic map ( CLK_FREQ_HZ => CLK_FREQ_HZ, SCL_FREQ_HZ => SCL_FREQ_HZ )
        port map ( clk        => clk,
                    rst        => rst,
                    start_tx   => start_tx,
                    rw_sel     => rw_sel,
                    slave_addr => slave_addr,
                    reg_addr   => reg_addr,
                    data_rd    => data_rd,
                    busy       => busy,
                    done       => done,
                    ack_error  => ack_error,
                    scl        => scl,
                    sda_in     => sda_in,
                    sda_out    => sda_out,
                    sda_oe     => sda_oe );

    -- bus open-drain: master & slave sama-sama bisa menarik rendah, pull-up default '1'
    sda_bus <= '0' when (sda_oe = '1' and sda_out = '0') else
               '0' when slave_drive = '0' else
               '1';
    sda_in <= sda_bus;

    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- ======== Model slave sederhana (behavioral, bukan sintesis) ========
    -- Mengamati pola SCL/SDA, membalas ACK setelah menerima 8 bit alamat
    -- dan 8 bit data, lalu mengirim SLAVE_READ_BYTE saat fase baca.
    -- Ditulis sekuensial eksplisit (bukan loop generik) supaya setiap pulsa SCL
    -- yang dihasilkan i2c_master (termasuk pulsa START dan REPEATED START yang
    -- tidak membawa bit data) ditangani secara eksak sesuai urutan kemunculannya,
    -- dan supaya bit yang DI-DRIVE oleh slave (fase baca) di-setting pada tepi
    -- SCL yang tepat (awal fase rendah tiap bit, sebelum master menyampel).
    slave_proc: process
    begin
        slave_drive <= 'Z';
        wait until rst = '0';

        -- Lewati 1 pulsa SCL milik kondisi START (tidak membawa bit data)
        wait until rising_edge(scl);
        wait until falling_edge(scl);

        -- ===== Byte 1: alamat slave + bit W (8 bit) =====
        for i in 0 to 7 loop
            wait until rising_edge(scl);
        end loop;
        wait until falling_edge(scl);
        slave_drive <= '0';  -- ACK
        wait until falling_edge(scl);
        slave_drive <= 'Z';

        -- ===== Byte 2: data (reg_addr / pointer register), 8 bit =====
        for i in 0 to 7 loop
            wait until rising_edge(scl);
        end loop;
        wait until falling_edge(scl);
        slave_drive <= '0';  -- ACK
        wait until falling_edge(scl);
        slave_drive <= 'Z';

        -- Lewati 1 pulsa SCL milik REPEATED START (tidak membawa bit data)
        wait until rising_edge(scl);
        wait until falling_edge(scl);

        -- ===== Byte 3: alamat slave + bit R (8 bit) =====
        for i in 0 to 7 loop
            wait until rising_edge(scl);
        end loop;
        wait until falling_edge(scl);
        slave_drive <= '0';  -- ACK, tepi ini sekaligus menjadi awal fase-rendah bit7 berikutnya
        wait until falling_edge(scl);

        -- ===== Byte 4: slave mengirim SLAVE_READ_BYTE, MSB dulu =====
        -- bit7 di-setting langsung memakai tepi falling_edge yang baru saja
        -- didapat (akhir ACK = awal fase-rendah bit7), tanpa menunggu tepi baru,
        -- supaya datanya sudah stabil SEBELUM master menyampelnya.
        if SLAVE_READ_BYTE(7) = '0' then slave_drive <= '0'; else slave_drive <= 'Z'; end if;
        wait until rising_edge(scl);   -- master menyampel bit7
        for i in 6 downto 0 loop
            wait until falling_edge(scl);   -- awal fase-rendah bit ke-i
            if SLAVE_READ_BYTE(i) = '0' then slave_drive <= '0'; else slave_drive <= 'Z'; end if;
            wait until rising_edge(scl);    -- master menyampel bit ke-i
        end loop;
        wait until falling_edge(scl);
        slave_drive <= 'Z';  -- lepas bus, biarkan master mengirim NACK lalu STOP

        wait;
    end process;

    -- ======== Stimulus ========
    stim_proc: process
    begin
        rst <= '1';
        wait for CLK_PERIOD*5;
        rst <= '0';
        wait for CLK_PERIOD*5;

        -- picu satu transaksi: tulis reg_addr=0x00, lalu baca 1 byte
        rw_sel     <= '1';
        slave_addr <= "1001000";
        reg_addr   <= x"00";
        start_tx   <= '1';
        wait for CLK_PERIOD;
        start_tx   <= '0';

        wait until done = '1';
        wait for CLK_PERIOD*5;

        report "Transaksi selesai. ack_error=" & std_logic'image(ack_error) &
               " , data_rd(desimal)=" & integer'image(to_integer(unsigned(data_rd)));

        assert (ack_error = '0')
            report "GAGAL: slave tidak membalas ACK" severity error;
        assert (data_rd = SLAVE_READ_BYTE)
            report "GAGAL: data yang dibaca tidak sesuai dengan yang dikirim slave" severity error;
        if (ack_error = '0' and data_rd = SLAVE_READ_BYTE) then
            report "OK: transaksi I2C (write reg_addr + read 1 byte) berhasil diverifikasi";
        end if;

        report "===== Simulasi tb_i2c_master selesai =====";
        wait;
    end process;

end sim;