module mod_fpgaudio
  ( output logic [0:6] o_lcd7_0
  , output logic [0:6] o_lcd7_1
  , output logic o_led_1hz
  , output logic o_led_48khz
  
  , output logic [0:4] o_debug_pins

  , output logic o_i2c_sdclk
  , inout wire b_i2c_sdat // Note: Quartus requires this to be wire as during
                          // synthesis it cannnot deduce that the output of the
                          // I2C module will pipe into a pin-assignment.

  , output logic o_audio_dacdat
  , inout logic b_audio_bclk
  , inout logic b_audio_adclrck
  , inout logic b_audio_daclrck
  , input logic i_audio_adcdat

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

  logic i2c_ready;
  logic [3:0] i2c_fault_code = 4'hf;
  mod_i2c_master u_i2c_driver
    ( .o_done(i2c_ready)
    , .o_fault_code(i2c_fault_code)
    , .o_i2c_sdclk(o_i2c_sdclk)
    , .b_i2c_sdat(b_i2c_sdat)
    , .i_i2c_addr(7'b0011010)
    , .i_i2c_register(7'b0000110)
    , .i_i2c_data(9'b0_00_1_0000)
    , .i_mode_read_not_write(1'b0) // Always write
    , .i_nrst(i_nrst)
    , .i_i2c_clk(clk_200khz)
    );

  // Debugging Features.
  assign o_led_1hz = clk_1hz;
  assign o_led_48khz = clk_48khz;
  assign o_debug_pins[0] = clk_200khz;
  assign o_debug_pins[1] = o_i2c_sdclk;
  assign o_debug_pins[2] = b_i2c_sdat;
  assign o_debug_pins[3] = i_nrst;
  assign o_debug_pins[4] = i2c_ready;
  
  mod_byte_display u_display
    ( .o_lcd_upper_nibble(o_lcd7_1)
    , .o_lcd_lower_nibble(o_lcd7_0)
    , .i_value(i2c_fault_code)
    , .i_clk(i_clk)
    , .i_nrst(i_nrst)
    );
endmodule
