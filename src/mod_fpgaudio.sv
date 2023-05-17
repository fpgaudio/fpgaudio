module mod_fpgaudio
  ( output logic [0:6] o_lcd7_0
  , output logic [0:6] o_lcd7_1
  , output logic o_led_1hz

  , input logic i_clk
  , input logic i_nrst
  );

  logic clk_1hz;
  mod_clock u_clock
    ( .o_clk1hz(clk_1hz)
    , .i_clk(i_clk)
    );
  assign o_led_1hz = clk_1hz;

  logic [7:0] counter = 0;
  always_ff @(posedge clk_1hz or negedge i_nrst)
    counter <= (~i_nrst) ? 0 : counter + 1;

  mod_byte_display u_display
    ( .o_lcd_upper_nibble(o_lcd7_1)
    , .o_lcd_lower_nibble(o_lcd7_0)
    , .i_value(counter)
    , .i_clk(i_clk)
    , .i_nrst(i_nrst)
    );

endmodule
