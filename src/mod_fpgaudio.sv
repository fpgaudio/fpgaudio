module mod_fpgaudio
  ( output logic [0:6] o_lcd7_0
  , output logic [0:6] o_lcd7_1
  , output logic o_led_1hz
  , output logic o_led_48khz
  
  , output logic [0:4] o_debug_pins

  , output logic o_i2c_sdclk
  , inout tri b_i2c_sdat

  , output logic o_aud_dacdat
  , inout tri b_aud_daclrck
  , input logic i_aud_bclk

  , input logic i_clk
  , input logic i_nrst
  );

  // Clocking Signals
  logic clk_1hz;
  logic clk_48khz;
  logic clk_200khz;
  mod_clock u_clock
    ( .o_clk1hz(clk_1hz)
    , .o_clk48khz(clk_48khz)
    , .o_clk200khz(clk_200khz)
    , .i_clk(i_clk)
    );

  logic [7:0] audio_drv_fault_code  = 8'hff;
  logic audio_initialized;
  mod_audio_drv u_audio_driver
    ( .o_ready(audio_initialized)
    , .o_fault_code(audio_drv_fault_code)
    , .o_aud_dacdat(o_aud_dacdat)
    , .b_aud_daclrck(b_aud_daclrck)
    , .i_aud_bclk(i_aud_bclk)
    , .o_i2c_scl(o_i2c_sdclk)
    , .b_i2c_sdl(b_i2c_sdat)
    , .i_nrst(i_nrst)
    , .i_i2c_clk(clk_200khz)
    , .i_clk(i_clk)
    );

  // Debugging Features.
  assign o_led_1hz = clk_1hz;
  assign o_led_48khz = clk_48khz;
  assign o_debug_pins[0] = clk_200khz;
  // Output the I2C line on pins 1 and 2
  assign o_debug_pins[1] = o_i2c_sdclk;
  assign o_debug_pins[2] = 
    b_i2c_sdat == 1'bz ? 1'b1
    : ( b_i2c_sdat == 1'b1 ? 1'b1
    : 1'b0
    );
  assign o_debug_pins[3] = o_aud_dacdat;
  assign o_debug_pins[4] = audio_initialized;
  
  mod_byte_display u_display
    ( .o_lcd_upper_nibble(o_lcd7_1)
    , .o_lcd_lower_nibble(o_lcd7_0)
    , .i_value(audio_drv_fault_code)
    , .i_clk(i_clk)
    , .i_nrst(i_nrst)
    );
endmodule
