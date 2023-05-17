module mod_byte_display
  ( output logic [0:6] o_lcd_upper_nibble
  , output logic [0:6] o_lcd_lower_nibble
  , input logic [7:0] i_value
  , input logic i_clk
  , input logic i_nrst
  );

  mod_7seg u_lcd_upper
    ( .o_segments(o_lcd_upper_nibble)
    , .i_value(i_value[7:4])
    , .i_clk(i_clk)
    , .i_nrst(i_nrst)
    );

  mod_7seg u_lcd_lower
    ( .o_segments(o_lcd_lower_nibble)
    , .i_value(i_value[3:0])
    , .i_clk(i_clk)
    , .i_nrst(i_nrst)
    );
endmodule
