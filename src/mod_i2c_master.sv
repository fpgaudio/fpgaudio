module mod_i2c_master
  ( output logic o_done // Pulled high when the I2C transaction is finished.
  , output logic [3:0] o_fault_code // Spits out a non-zero value upon an error

  , output logic o_i2c_sdclk // The I2C SDCLK line.
  , inout tri b_i2c_sdat // The I2C SDAT line.

  , input logic [6:0] i_i2c_addr // The chip I2C address
  , input logic [6:0] i_i2c_register // The chip register to read/write to
  , input logic [8:0] i_i2c_data // 9 bits of data to send.
  , input logic i_mode_read_not_write // High to read, low to write

  , input logic i_nrst // Async, negedge reset
  , input logic i_i2c_clk // I2C clock. Must be between 200khz and 800khz.
                          // This module will output a SCL of half the speed.
  );

  localparam STATE_BEGIN = 10'd0;
  localparam STATE_START_CONDITION = 10'd1;
  logic [9:0] state;
  logic i2c_sdc;
  logic i2c_sdl;

  always @(posedge i_i2c_clk or negedge i_nrst) begin
    if (i_nrst == 1'b0) begin
      // Handle a reset
      state <= STATE_BEGIN;
      o_done <= 1'b0;
    end else begin
      if (!(o_fault_code == 4'd0 || o_fault_code == 4'hf)) begin
      // A fault has ocurred, block execution
      end else begin
        case (state)
          STATE_BEGIN: begin
            o_fault_code <= ((o_done == 1'b1) ? 4'b1 : 4'b0);
            i2c_sdc <= 1'b1;
            i2c_sdl <= 1'b1;
          end
          // Start condition
          STATE_START_CONDITION: begin
            i2c_sdc <= 1'b1;
            i2c_sdl <= 1'b0;
          end
          // Address Send
          10'd2: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_addr[6];
          end
          10'd3: begin
            i2c_sdc <= 1'b1;
          end
          10'd4: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_addr[5];
          end
          10'd5: begin
            i2c_sdc <= 1'b1;
          end
          10'd6: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_addr[4];
          end
          10'd7: begin
            i2c_sdc <= 1'b1;
          end
          10'd8: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_addr[3];
          end
          10'd9: begin
            i2c_sdc <= 1'b1;
          end
          10'd10: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_addr[2];
          end
          10'd11: begin
            i2c_sdc <= 1'b1;
          end
          10'd12: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_addr[1];
          end
          10'd13: begin
            i2c_sdc <= 1'b1;
          end
          10'd14: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_addr[0];
          end
          10'd15: begin
            i2c_sdc <= 1'b1;
          end
          10'd16: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_mode_read_not_write;
          end
          10'd17: begin
            i2c_sdc <= 1'b1;
          end
          // Wait for ACK
          10'd18: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= 1'b1;
          end
          10'd19: begin
            i2c_sdc <= 1'b1;
            // At this point, the slave must've pulled the DAT line low for an
            // ACK.
            o_fault_code <= i2c_sdl == 1 ? 4'd2 : 0;
          end
          // We may now send the data. First, emit the register
          10'd20: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_register[6];
          end
          10'd21: begin
            i2c_sdc <= 1'b1;
          end
          10'd22: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_register[5];
          end
          10'd23: begin
            i2c_sdc <= 1'b1;
          end
          10'd24: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_register[4];
          end
          10'd25: begin
            i2c_sdc <= 1'b1;
          end
          10'd26: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_register[3];
          end
          10'd27: begin
            i2c_sdc <= 1'b1;
          end
          10'd28: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_register[2];
          end
          10'd29: begin
            i2c_sdc <= 1'b1;
          end
          10'd30: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_register[1];
          end
          10'd31: begin
            i2c_sdc <= 1'b1;
          end
          10'd32: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_register[0];
          end
          10'd33: begin
            i2c_sdc <= 1'b1;
          end
          // Send the first bit.
          10'd34: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_data[8];
          end
          10'd35: begin
            i2c_sdc <= 1'b1;
          end
          // Assert an ack.
          10'd36: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= 1'b1;
          end
          10'd37: begin
            i2c_sdc <= 1'b1;
            o_fault_code <= i2c_sdl == 1 ? 4'd3 : 0;
          end
          // Send the other chunks of data
          10'd38: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_data[7];
          end
          10'd39: begin
            i2c_sdc <= 1'b1;
          end
          10'd40: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_data[6];
          end
          10'd41: begin
            i2c_sdc <= 1'b1;
          end
          10'd42: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_data[5];
          end
          10'd43: begin
            i2c_sdc <= 1'b1;
          end
          10'd44: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_data[4];
          end
          10'd45: begin
            i2c_sdc <= 1'b1;
          end
          10'd46: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_data[3];
          end
          10'd47: begin
            i2c_sdc <= 1'b1;
          end
          10'd48: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_data[2];
          end
          10'd49: begin
            i2c_sdc <= 1'b1;
          end
          10'd50: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_data[1];
          end
          10'd51: begin
            i2c_sdc <= 1'b1;
          end
          10'd52: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= i_i2c_data[0];
          end
          10'd53: begin
            i2c_sdc <= 1'b1;
          end
          // Assert an ACK
          10'd54: begin
            i2c_sdc <= 1'b0;
          end
          10'd55: begin
            i2c_sdc <= 1'b1;
            o_fault_code <= i2c_sdl == 1 ? 4'd4 : 0;
          end
          // Send stop code.
          10'd56: begin
            i2c_sdc <= 1'b0;
            i2c_sdl <= 1'b0;
          end
          10'd57: begin
            i2c_sdc <= 1'b1;
            i2c_sdl <= 1'b0;
          end
          // Release bus
          10'd58: begin
            i2c_sdc  <= 1'b1;
            i2c_sdl <= 1'b1;
            o_done <= 1'b1;
            o_fault_code <= 4'hf;
          end
          default: begin
            o_fault_code <= 4'd5;
          end
        endcase

        // Advance the state machine
        if (i_nrst != 1'b0 && state < 10'd58) begin
          state <= state + 1;
        end else begin
          // Do not advance the machine if we reached the final state.
        end
      end
    end
  end

  assign o_i2c_sdclk = i2c_sdc;
  assign b_i2c_sdat = (~i_nrst ? 1'b0 : i2c_sdl) == 1'b1 ? 1'bz : 1'b0;
endmodule
