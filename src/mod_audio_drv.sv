module mod_audio_drv#
  ( parameter CODEC_I2C_ADDR = 7'b0011010
  )
  ( output logic o_ready // Raised when the CODEC is ready to receive data.
  , output logic [7:0] o_fault_code // The fault.

  , output logic o_aud_dacdat
  , inout tri b_aud_daclrck
  , input logic i_aud_bclk

  , output logic o_i2c_scl // The I2C clock line
  , inout tri b_i2c_sdl // The I2C data line
  
  , input [15:0] i_data

  , input logic i_nrst
  , input logic i_i2c_clk // The I2C Clock
  , input logic i_clk // The global clock
  );

  logic chip_initialized = 1'b0;
  logic [3:0] config_err;
  mod_audio_drv_config u_audio_driver_configurator
    ( .o_init_ready(chip_initialized)
    , .o_i2c_fault_code(config_err)
    , .o_i2c_scl(o_i2c_scl)
    , .b_i2c_sdl(b_i2c_sdl)
    , .i_nrst(i_nrst)
    , .i_i2c_clk(i_i2c_clk)
    , .i_clk(i_clk)
    );

  logic [3:0] serial_state;
  mod_audio_drv_serial u_audio_driver_serial
    ( .o_done(serial_done)
    , .o_state(serial_faulted)
    , .o_aud_dacdat(o_aud_dacdat)
    , .i_data(32'd100)
    , .i_aud_bclk(i_aud_bclk)
    , .i_aud_daclrck(i_aud_daclrck)
    , .i_clk(i_clk)
    , .i_nrst(i_nrst)
    );

  assign o_ready = chip_initialized;
  assign o_fault_code[7:4] = serial_state;
  assign o_fault_code[3:0] = config_err;
endmodule
