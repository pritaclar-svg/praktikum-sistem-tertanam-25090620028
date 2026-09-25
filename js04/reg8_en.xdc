## Clock 100 MHz (Pin W5)
set_property PACKAGE_PIN W5 [get_ports clk]						
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Switch SW(7 downto 0) -> Data Input d
set_property PACKAGE_PIN V17 [get_ports {d[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {d[0]}]
set_property PACKAGE_PIN V16 [get_ports {d[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {d[1]}]
set_property PACKAGE_PIN W16 [get_ports {d[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {d[2]}]
set_property PACKAGE_PIN W17 [get_ports {d[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {d[3]}]
set_property PACKAGE_PIN W15 [get_ports {d[4]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {d[4]}]
set_property PACKAGE_PIN V15 [get_ports {d[5]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {d[5]}]
set_property PACKAGE_PIN W14 [get_ports {d[6]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {d[6]}]
set_property PACKAGE_PIN W13 [get_ports {d[7]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {d[7]}]

## LED(7 downto 0) -> Data Output q
set_property PACKAGE_PIN U16 [get_ports {q[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {q[0]}]
set_property PACKAGE_PIN E19 [get_ports {q[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {q[1]}]
set_property PACKAGE_PIN U19 [get_ports {q[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {q[2]}]
set_property PACKAGE_PIN V19 [get_ports {q[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {q[3]}]
set_property PACKAGE_PIN W18 [get_ports {q[4]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {q[4]}]
set_property PACKAGE_PIN U15 [get_ports {q[5]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {q[5]}]
set_property PACKAGE_PIN U14 [get_ports {q[6]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {q[6]}]
set_property PACKAGE_PIN V14 [get_ports {q[7]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {q[7]}]

## Tombol Push Button
# btnC -> Enable
set_property PACKAGE_PIN U18 [get_ports en]						
set_property IOSTANDARD LVCMOS33 [get_ports en]
# btnU -> Reset
set_property PACKAGE_PIN T18 [get_ports rst]						
set_property IOSTANDARD LVCMOS33 [get_ports rst]