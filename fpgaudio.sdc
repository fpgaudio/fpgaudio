create_clock -period 20 [get_ports i_clk]
create_clock -period 20833 [get_ports i_aud_bclk]
create_generated_clock -multiply_by 73 -divide_by 297 -source [get_ports i_clk] [get_ports o_aud_xck]
derive_pll_clocks
derive_clock_uncertainty