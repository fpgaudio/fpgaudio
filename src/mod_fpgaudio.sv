module mod_fpgaudio
  ( output logic [0:6] o_lcd7_0
  , output logic [0:6] o_lcd7_1
  , output logic o_led_1hz

  , input logic i_midi_data

  , input logic i_clk
  , input logic i_nrst
  );

  // Clocking Signals
  logic clk_1hz;
  mod_clock u_clock
    ( .o_clk1hz(clk_1hz)
    , .i_clk(i_clk)
    );
  // Blink LED at 1Hz for a sanity check.
  assign o_led_1hz = clk_1hz;

  logic [7:0] midi_decoded;
  logic midi_valid;
  midi_receiver u_midi_receiver
    ( .clk(i_clk)
    , .reset(~i_nrst)
    , .din(i_midi_data)
    , .dout(midi_decoded)
    , .valid(midi_valid)
    );

  logic [7:0] midi_latched = 0;
  always_ff @(posedge i_clk)
    if (midi_valid) midi_latched <= midi_decoded;

  mod_byte_display u_display
    ( .o_lcd_upper_nibble(o_lcd7_1)
    , .o_lcd_lower_nibble(o_lcd7_0)
    , .i_value(midi_latched)
    , .i_clk(i_clk)
    , .i_nrst(i_nrst)
    );
endmodule
