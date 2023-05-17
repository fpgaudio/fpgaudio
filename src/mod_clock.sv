module mod_clock#
  (
    parameter INPUT_CLOCK_SPEED = 50_000_000
  )
  ( output logic o_clk1hz
  , input logic i_clk
  );

  logic [31:0] counter = 0;

  always_ff @(posedge i_clk) begin
    counter <= (counter + 1) % (INPUT_CLOCK_SPEED);
    o_clk1hz <= (counter < INPUT_CLOCK_SPEED / 2) ? 1'b1 : 1'b0;
  end
endmodule
