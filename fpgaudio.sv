module fpgaudio
  ( input i_nrst
  , input i_clk
  , output o_aud_xck
  , input i_aud_bclk
  , output o_aud_dacdat
  , input i_aud_daclrck
  , inout b_sdl
  , output o_scl
  , output [0:6] ss1
  , output [0:6] ss2
  , output [15:0] o_led_array
  );
  
  // Synthesizer Driver
  logic [31:0] current_time = 32'd0;
  logic synth_trigger;
  assign synth_trigger = i_aud_bclk;
  always @(posedge i_aud_bclk) begin
    current_time <= current_time + 32'd1;
  end
  
  logic [31:0] synth_sound;
  logic synth_ready;
  mod_synth u_synthesizer
	( .o_sound(synth_sound)
	, .o_ready(synth_ready)
	, .i_time(current_time)
	, .i_atten_harmonics(
	 '{ 32'd1 << 32'd15
	  , 32'd0 << 32'd15
	  , 32'd0 << 32'd15
	  , 32'd0 << 32'd15
	  , 32'd0 << 32'd15
	  })
	, .i_atten_out(32'd1 << 32'd15)
	, .i_trigger(synth_trigger)
	, .i_clk(i_clk)
	, .i_nrst(i_nrst)
	);

  // MCLK on the WM8731 Chip, Running at 12.288MHz
  logic reset_source_reset;
  AudioClocker myAudioClocker
    ( .audio_clk_clk(o_aud_xck)
    , .ref_clk_clk(i_clk)
    , .ref_reset_reset(i_nrst)
    , .reset_source_reset(reset_source_reset)
    );

  localparam STATE_START = 4'd0;
  localparam STATE_INIT = 4'd1;
  localparam STATE_RUNNING = 4'd2;
  localparam STATE_ERROR = 4'd3;
  logic [3:0] state;
  logic [3:0] state_next;
  initial state = STATE_START;
  always @ (posedge i_clk or negedge i_nrst) begin
    if (i_nrst == 1'b0) begin
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
    ( .rst(i_nrst)
    , .clk(i_clk)
    , .initPulse(audio_init)
    , .SDAT(b_sdl)
    , .SDCLK(o_scl)
    , .doneInit(audioDoneInit)
    , .audioInitError(audioInitError)

    , .manualSend(1'b0)
    , .manualRegister(7'd0)
    , .manualData(9'd0)
    , .manualDone(_unused_myAudioInit_manualDone)
  );

  wire DACDone;

  logic [31:0] current_dac_data;
  assign current_dac_data = 16'(synth_sound);

  AudioDAC myDAC
  ( .clk(i_clk)
  , .rst(i_nrst)
  , .AUD_BCLK(i_aud_bclk)
  , .AUD_DACLRCK(i_aud_daclrck)
  , .data(current_dac_data)
  , .done(DACDone)
  , .AUD_DACDAT(o_aud_dacdat)
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
  mod_vumeter u_vumeter(o_led_array, current_dac_data);
endmodule
