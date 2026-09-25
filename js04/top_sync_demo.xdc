## Clock 100 MHz (Pin W5)
set_property PACKAGE_PIN W5 [get_ports clk]						
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Tombol btnC (Pin U18)
set_property PACKAGE_PIN U18 [get_ports btnC]						
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## LED 0 (Pin U16)
set_property PACKAGE_PIN U16 [get_ports led0]					
set_property IOSTANDARD LVCMOS33 [get_ports led0]