module mod_fpgaudio
  ( output logic [0:6] o_lcd7_0
  , output logic [0:6] o_lcd7_1
  , output logic o_led_1hz

  , output logic o_audio_dacdat
  , inout logic i_audio_bclk
  , inout logic i_audio_adclrck
  , inout logic i_audio_daclrck
  , input logic i_audio_adcdat

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

  logic [23:0] write_data = 0;
  logic audio_in_ready;
  logic audio_next_sample_ready;
  logic [23:0] read_data_left;
  logic [23:0] read_data_right;

  audio_codec u_sound_driver
    ( .CLOCK_50(i_clk)
    , .reset(~i_nrst)
    , .read_s(1'b0)
    , .write_s(1'b1)
    , .writedata_left(write_data)
    , .writedata_right(write_data)
    , .AUD_ADCDAT(i_audio_adcdat)
    , .AUD_BCLK(i_audio_bclk)
    , .AUD_ADCLRCK(i_audio_adclrck)
    , .AUD_DACLRCK(i_audio_daclrck)
    , .read_ready(audio_in_ready)
    , .write_ready(audio_next_sample_ready)
    , .readdata_left(read_data_left)
    , .readdata_right(readdata_right)
    , .AUD_DACDAT(o_audio_dacdat)
    );
  

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
