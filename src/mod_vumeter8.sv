module mod_vumeter8
  ( output logic [7:0] o_led_amps
  , input logic [7:0] i_in
  );

  always_comb begin
    for (int i = 0; i < 8; i = i + 1) begin
      o_led_amps[i] = (i_in > (2048 * i)) ? 1'b1 : 1'b0;
    end
  end
endmodule
