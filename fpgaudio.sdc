create_clock -period 20 [get_ports i_clk]
derive_clock_uncertainty
set_input_delay 0 -clock i_clk [all_inputs]
set_output_delay 0 -clock i_clk [all_outputs]
