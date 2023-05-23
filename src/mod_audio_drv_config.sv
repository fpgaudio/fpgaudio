module mod_audio_drv_config#
  ( parameter CODEC_I2C_ADDR = 7'b0011010
  )
  ( output logic o_init_ready // Raised high when the codec is initialized.
  , output logic [3:0] o_i2c_fault_code // The I2C fault code.
  , output logic [3:0] o_current_driver_state // The current driver state
                                              // useful for debugging

  , output logic o_i2c_scl // The I2C clock line
  , inout tri b_i2c_sdl // The I2C data line

  , input logic i_nrst
  , input logic i_clk // The global clock
  );

  localparam STATE_BEGIN = 4'd0;
  localparam STATE_WRITE_POWER = 4'd1;
  localparam STATE_WRITE_POWER_DONE = 4'd2;
  localparam STATE_WRITE_AUDIO_FORMAT = 4'd3;
  localparam STATE_WRITE_AUDIO_FORMAT_DONE = 4'd4;
  localparam STATE_WRITE_ANALOG_PATH = 4'd5;
  localparam STATE_WRITE_ANALOG_PATH_DONE = 4'd6;
  localparam STATE_WRITE_DIGITAL_PATH = 4'd7;
  localparam STATE_WRITE_DIGITAL_PATH_DONE = 4'd8;
  localparam STATE_WRITE_ACTIVATION = 4'd9;
  localparam STATE_WRITE_ACTIVATION_DONE = 4'd10;
  localparam STATE_INITIALIZED = 4'd11;
  logic [3:0] state = 0;

  // Register definitions
  localparam WM8731_REG_LEFT_LINE_IN = 7'b0000000;
  localparam WM8731_REG_RIGHT_LINE_IN = 7'b0000001;
  localparam WM8731_REG_LEFT_HEADPHONE_OUT = 7'b0000010;
  localparam WM8731_REG_RIGHT_HEADPHONE_OUT = 7'b0000011;
  localparam WM8731_REG_ANALOGUE_AUDIO_PATH_CTRL = 7'b0000100;
  localparam WM8731_REG_DIGITAL_AUDIO_PATH_CTRL = 7'b0000101;
  localparam WM8731_REG_POWER_DOWN_CTRL = 7'b0000110;
  localparam WM8731_REG_DIGITAL_AUDIO_INTERFACE_FMT = 7'b0000111;
  localparam WM8731_REG_SAMPLING_CTRL = 7'b0001000;
  localparam WM8731_REG_ACTIVE_CTRL = 7'b0001001;
  localparam WM8731_REG_RESET = 7'b0001111;

  logic i2c_done = 0;
  logic i2c_flush = 0;
  logic [6:0] i2c_current_reg = 0;
  logic [8:0] i2c_current_data = 0;
  mod_i2c_master u_i2c_drv
    ( .o_done(i2c_done)
    , .o_fault_code(o_i2c_fault_code)
    , .o_i2c_sdclk(o_i2c_scl)
    , .b_i2c_sdat(b_i2c_sdl)
    , .i_i2c_addr(CODEC_I2C_ADDR)
    , .i_i2c_register(i2c_current_reg)
    , .i_i2c_data(i2c_current_data)
    , .i_mode_read_not_write(1'b0)
    , .i_nrst(i2c_flush)
    , .i_clk(i_clk)
    );

  always @(posedge i_clk or negedge i_nrst) begin
    if (!i_nrst) begin
      state <= STATE_BEGIN;
    end else begin
      // State machine behavior
      case (state)
        // Initialization stages require performing I2C transactions.
        STATE_BEGIN: begin
          o_init_ready <= 1'b0;
        end
        STATE_WRITE_POWER: begin
          i2c_flush <= 1'b1;
          i2c_current_reg <= WM8731_REG_POWER_DOWN_CTRL;
          // Disable all ADC features.
          i2c_current_data <= 7'b00_0_0_0_0_0_1_1_0;
        end
        STATE_WRITE_AUDIO_FORMAT: begin
          i2c_flush <= 1'b1;
          i2c_current_reg <= WM8731_REG_DIGITAL_AUDIO_INTERFACE_FMT;
          // DSP Mode: Frame Sync + 2 Data Packed Words
          // 16 bit data bit length
          // DACLRC posedge trigger
          i2c_current_data <= 9'b00_0_0_0_1_00_11;
        end
        STATE_WRITE_ANALOG_PATH: begin
          i2c_flush <= 1'b1;
          i2c_current_reg <= WM8731_REG_ANALOGUE_AUDIO_PATH_CTRL;
          // Only output the DAC
          i2c_current_data <= 9'b0_00_0_1_0_0_0_0;
        end
        STATE_WRITE_DIGITAL_PATH: begin
          i2c_flush <= 1'b1;
          i2c_current_reg <= WM8731_REG_DIGITAL_AUDIO_PATH_CTRL;
          // Don't do anything funny, thank you.
          i2c_current_data <= 9'b00000_0_0_00_0;
        end
        STATE_WRITE_ACTIVATION: begin
          i2c_flush <= 1'b1;
          i2c_current_reg <= WM8731_REG_ACTIVE_CTRL;
          // Enable
          i2c_current_data <= 9'b0_0000000_1;
        end

        STATE_WRITE_POWER_DONE
      , STATE_WRITE_AUDIO_FORMAT_DONE
      , STATE_WRITE_ANALOG_PATH_DONE
      , STATE_WRITE_DIGITAL_PATH_DONE: begin
          i2c_flush <= 1'b0;
        end
        STATE_WRITE_ACTIVATION_DONE: begin
          // In this state, we actually don't want to disable I2C flush
          // in order to prevent the bus from going low.
        end
        STATE_INITIALIZED: begin
          o_init_ready <= 1'b1;
        end
        // Undefined state is a NOP
        default: begin
        end
      endcase

      // State machine transition
      case (state)
        STATE_BEGIN: state <= STATE_WRITE_POWER;

        STATE_WRITE_POWER
      , STATE_WRITE_AUDIO_FORMAT
      , STATE_WRITE_ANALOG_PATH
      , STATE_WRITE_DIGITAL_PATH
      , STATE_WRITE_ACTIVATION: begin
          if (i2c_done) begin
            state <= state + 1'b1;
          end else begin
            // Wait until i2c is done.
          end
        end

        STATE_WRITE_POWER_DONE
      , STATE_WRITE_AUDIO_FORMAT_DONE
      , STATE_WRITE_ANALOG_PATH_DONE
      , STATE_WRITE_DIGITAL_PATH_DONE
      , STATE_WRITE_ACTIVATION_DONE: begin
          state <= state + 1'b1;
        end

        STATE_INITIALIZED: begin
          // Stay in this state.
        end

        default: begin
          // Unconfigured state is a stop.
        end
      endcase
    end
  end

  assign o_current_driver_state = state;
endmodule
