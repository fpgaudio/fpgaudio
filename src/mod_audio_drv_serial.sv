module mod_audio_drv_serial
  ( output logic o_done
  , output logic [3:0] o_state
  , output logic o_aud_dacdat
  , input [31:0] i_data

  , input logic i_aud_bclk
  , input logic i_aud_daclrck

  , input logic i_clk
  , input logic i_nrst
  );

  localparam STATE_BEGIN = 4'd0;
  localparam STATE_SLEEP = 4'd1;
  localparam STATE_WRITE = 4'd2;
  localparam STATE_WRITTEN = 4'd3;
  localparam STATE_FAULT = 4'd4;

  logic [3:0] state;
  logic [3:0] next_state;

  logic [4:0] data_idx;
  initial data_idx = 5'd31;
  logic [31:0] data_local = 5'd0;

  always @(posedge i_aud_bclk or negedge i_nrst) begin
    if (i_nrst == 1'b0) begin
      state <= STATE_BEGIN;
      data_idx <= 5'd31;
    end else begin
      state <= next_state;

      case (state)
        STATE_SLEEP: begin
          if (i_aud_daclrck == 1'b1)
            data_local <= i_data;
        end
        STATE_WRITE: begin
          data_idx <= data_idx - 5'd1;
        end
        STATE_WRITTEN: begin
          data_idx <= 5'd31;
        end
        default: begin
          // A critical error has ocurred.
        end
      endcase
    end
  end

  always @(*) begin
    o_done = 1'b0;

    case (state)
      STATE_BEGIN: begin
        next_state = STATE_SLEEP;
      end
      STATE_SLEEP: begin
        next_state = (i_aud_daclrck == 1'b1) ? STATE_WRITE : STATE_SLEEP;
      end
      STATE_WRITE: begin
        next_state = data_idx == 5'd0 ? STATE_WRITTEN : STATE_WRITE;
      end
      STATE_WRITTEN: begin
        o_done = 1'b1;
        next_state = STATE_SLEEP;
      end
      default: begin
        next_state = STATE_FAULT;
      end
    endcase
  end

  always @(*) begin
    o_aud_dacdat = data_local[data_idx];
  end
endmodule
