module mod_synth_driver
  ( output logic [31:0] o_sound
  , output logic o_synth_ready__
  , input logic [31:0] i_current_freq
  , input logic [7:0] i_palm_ampl
  , input logic i_play
  , input logic i_aud_clk
  , input logic i_clk
  , input logic i_nrst
  );

  logic [31:0] current_time = 32'd0;
  logic [31:0] sample_counter = 32'd0;

  always @(posedge i_clk) begin
    if (sample_counter == 32'd1042) begin
      sample_counter <= 32'd0;
      current_time <= current_time + 32'd1;
    end else begin
      sample_counter <= sample_counter + 32'd1;
    end
  end

  logic [3:0] state = STATE_BEGIN;
  logic [3:0] state_next = STATE_BEGIN;
  localparam STATE_BEGIN = 4'd0;
  localparam STATE_TRIGGER = 4'd1;
  localparam STATE_WAIT_FOR_SAMPLE = 4'd2;
  localparam STATE_SAMPLED = 4'd3;

  logic synth_trigger;
  logic synth_ready;
  logic [31:0] synth_sound;
  mod_synth u_sine
    ( synth_sound
    , synth_ready
    , current_time
    , i_current_freq
    , '{32'd1 << 15
      , 32'd0 << 15
      , 32'd0 << 15
      , 32'd0 << 15
      , 32'd0 << 15
      }
    , i_play ? (32'(i_palm_ampl) << 32'd7) : 32'd0
    , synth_trigger
    , i_clk
    , i_nrst
    );
  assign o_synth_ready__ = synth_ready;
  assign o_sound = { 16'(synth_sound), 16'(synth_sound) };

  always @(posedge i_clk) begin
    if (!i_nrst) begin
      state <= STATE_BEGIN;
    end else begin
      case (state)
        STATE_BEGIN: begin
          state_next <= STATE_TRIGGER;
        end

        STATE_TRIGGER: begin
          synth_trigger <= 1'b1;
          state_next <= STATE_WAIT_FOR_SAMPLE;
        end

        STATE_WAIT_FOR_SAMPLE: begin
          synth_trigger <= 1'b0;
          state_next <= synth_ready ? STATE_SAMPLED : STATE_WAIT_FOR_SAMPLE;
        end

        STATE_SAMPLED: begin
          state_next <= STATE_TRIGGER;
        end

        default: begin
          state_next <= STATE_BEGIN;
        end
      endcase

      state <= state_next;
    end
  end
endmodule
