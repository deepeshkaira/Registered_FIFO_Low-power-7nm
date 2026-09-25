create_clock -name clk -period 10000.000 [get_ports clk]

set_clock_uncertainty 100.000 [get_clocks clk]
set_clock_transition 20.000 [get_clocks clk]

set_input_delay 1000.000 -clock [get_clocks clk] [get_ports {en_i data_i[*] data_valid_i rd_en_i}]
set_output_delay 1000.000 -clock [get_clocks clk] [get_ports {read_data_o[*] fifo_full_o fifo_empty_o}]

set_input_transition 50.000 [get_ports {rst_n en_i data_i[*] data_valid_i rd_en_i pd1_power_on_i pd1_isolation_i}]
set_load 5.000 [all_outputs]

set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports {pd1_power_on_i pd1_isolation_i}]
