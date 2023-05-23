module mod_vumeter#
  ( parameter QUANTIZATION_COUNT = 16
  )
  ( output logic [(QUANTIZATION_COUNT - 1):0] o_led_amps
  , input logic [31:0] i_aud_raw
  );

  logic signed [(QUANTIZATION_COUNT - 1):0] amp;
  logic signed [(QUANTIZATION_COUNT * 2 - 1):0] l;
  logic signed [(QUANTIZATION_COUNT * 2 - 1):0] r;

  always_comb begin
    l = { 16'(i_aud_raw[(QUANTIZATION_COUNT * 2 - 1)])
        , i_aud_raw[(QUANTIZATION_COUNT * 2 - 1):(QUANTIZATION_COUNT)]
        };
    r = { 16'(i_aud_raw[(QUANTIZATION_COUNT - 1)])
        , i_aud_raw[(QUANTIZATION_COUNT * 1 - 1):0] };
    amp = 16'((l + r) / 32'd2);
    for (int i = 0; i < QUANTIZATION_COUNT; i = i + 1) begin
      o_led_amps[i] = (amp > (2048 * i)) ? 1'b1 : 1'b0;
    end
  end

endmodule
