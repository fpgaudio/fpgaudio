module mod_clock#
  ( parameter INPUT_CLOCK_SPEED = 50_000_000
  )
  ( output logic o_clk1hz
  , output logic o_clk48khz
  , output logic o_clk200khz
  , input logic i_clk
  );

  logic [31:0] counter1hz = 0;
  always_ff @(posedge i_clk) begin
    counter1hz <= (counter1hz + 1) % (INPUT_CLOCK_SPEED);
    o_clk1hz <= (counter1hz < INPUT_CLOCK_SPEED / 2) ? 1'b1 : 1'b0;
  end
  
  localparam MOD_48KHZ = INPUT_CLOCK_SPEED / 48_000;
  logic [31:0] counter48khz = 0;
  always_ff @(posedge i_clk) begin
    counter48khz <= (counter48khz + 1) % MOD_48KHZ;
    o_clk48khz <= (counter48khz < MOD_48KHZ / 2) ? 1'b1 : 1'b0;
  end

  localparam MOD_200KHZ = INPUT_CLOCK_SPEED / 200_000;
  logic [31:0] counter200khz = 0;
  always_ff @(posedge i_clk) begin
    counter200khz <= (counter200khz + 1) % MOD_200KHZ;
    o_clk200khz <= (counter200khz < MOD_200KHZ / 2) ? 1'b1 : 1'b0;
  end
endmodule
