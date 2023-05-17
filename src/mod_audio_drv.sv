module mod_audio_drv#
  ( parameter CODEC_I2C_ADDR = 7'b0011010
  )
  ( output logic o_init_ready // Raised high when the codec is initialized.
  , output logic o_i2c_sdclk
  , inout logic b_i2c_sdat

  , input logic i_nrst
  , input logic i_clk100khz
  );

endmodule
