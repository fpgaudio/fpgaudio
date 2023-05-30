module fpgaudio
  ( input rst
  , input clk
  , output AUD_XCK
  , input AUD_BCLK
  , output AUD_DACDAT
  , input AUD_DACLRCK
  , inout SDAT
  , output SDCLK
  , output [0:6] ss1
  , output [0:6] ss2
  , output [15:0]redLEDs
  );

  wire audioClk;
  wire reset_source_reset;
  AudioClocker myAudioClocker
    ( .audio_clk_clk(audioClk)
    , .ref_clk_clk(clk)
    , .ref_reset_reset(rst)
    , .reset_source_reset(reset_source_reset)
    );

  assign AUD_XCK = audioClk;

  localparam STATE_START = 4'd0;
  localparam STATE_INIT = 4'd1;
  localparam STATE_RUNNING = 4'd2;
  localparam STATE_ERROR = 4'd3;
  reg [3:0] state;
  reg [3:0] state_next;
  initial state = STATE_START;
  always @ (posedge clk or negedge rst) begin
    if(rst == 1'b0) begin
        state <= STATE_START;
    end else begin
        state <= state_next;
    end
  end

  reg audio_init;
  wire audioDoneInit;
  wire [3:0]audioInitError;
  wire [3:0] audioInitErrorNotI2c;

  wire _unused_myAudioInit_manualDone;
  AudioInit myAudioInit
    ( .rst(rst)
    , .clk(clk)
    , .initPulse(audio_init)
    , .SDAT(SDAT)
    , .SDCLK(SDCLK)
    , .doneInit(audioDoneInit)
    , .audioInitError(audioInitError)

    , .manualSend(1'b0)
    , .manualRegister(7'd0)
    , .manualData(9'd0)
    , .manualDone(_unused_myAudioInit_manualDone)
  );

  wire DACDone;
  reg [31:0]currentDACData;
  initial currentDACData = 32'd0;

  always @(posedge clk) begin
    currentDACData <= currentDACData + 1000;
  end

  AudioDAC myDAC
  ( .clk(clk)
  , .rst(rst)
  , .AUD_BCLK(AUD_BCLK)
  , .AUD_DACLRCK(AUD_DACLRCK)
  , .data(currentDACData)
  , .done(DACDone)
  , .AUD_DACDAT(AUD_DACDAT)
  );

  always @ (*) begin
    audio_init = 1'b0;
    case (state)
      STATE_START: begin
        audio_init = 1'b1;
        state_next = STATE_INIT;    
      end
        
      STATE_INIT: begin
        state_next = audioDoneInit ? STATE_RUNNING : STATE_INIT;
      end

      STATE_RUNNING: begin
        state_next = STATE_RUNNING;
      end

      STATE_ERROR: begin
        state_next = STATE_ERROR;
      end
        
      default: begin
        state_next = STATE_ERROR;
      end
    endcase
  end

  mod_7seg u_global_state(ss1, state[3:0]);
  mod_7seg u_i2c_err_code(ss2, audioInitError);
  mod_vumeter u_vumeter(redLEDs, currentDACData);

endmodule
