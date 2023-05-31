# Clocks
create_clock -name i_clk -period 20 [get_ports i_clk]
create_generated_clock -name o_aud_xck -multiply_by 73 -divide_by 297 -source i_clk [get_ports o_aud_xck]
create_generated_clock -name i_aud_bclk -divide_by 256 -source o_aud_xck [get_ports i_aud_bclk]
create_generated_clock -name i2c_clk -divide_by 50000000 -multiply_by 200000 -source [get_ports i_clk] AudioInit:u_audio_initializer|mod_i2c_master:myI2c|i2c_clk

# Misc.
derive_pll_clocks
derive_clock_uncertainty