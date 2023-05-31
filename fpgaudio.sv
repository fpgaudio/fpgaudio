module fpgaudio
  ( input i_nrst
  , input i_clk
  , output o_aud_xck
  , input i_aud_bclk
  , output o_aud_dacdat
  , input i_aud_daclrck
  , inout b_sdl
  , output o_scl
  , input i_midi_inp
  , input i_lmc_uart
  , output [0:6] o_lcd7_0
  , output [0:6] o_lcd7_1
  , output [0:6] o_lcd7_2
  , output [0:6] o_lcd7_3
  , output [0:6] o_lcd7_4
  , output [0:6] o_lcd7_5
  , output [15:0] o_led_array
  , output [15:0] o_grn_led_array
  , output [7:0] o_dbg_pins
  );
  
  // MIDI Decoder
  logic [23:0] midi_bits;
  logic [3:0] midi_state;
  logic midi_note_on;
  midi_custom u_midi_decoder
    ( .clk(i_clk)
    , .serial(i_midi_inp)
    , .rst_n(i_nrst)
    , .out_bytes(midi_bits)
    , .state(midi_state)
    );
  assign midi_note_on = midi_bits[4];

  logic [15:0] midi_req_freq;
  midi_to_freq u_midi_freq_convert(.midi(midi_bits), .freq(midi_req_freq));
  
  // Synthesizer Driver
  logic [31:0] synth_sound;
  logic synth_ready;
  mod_synth_driver u_synth_drv
    ( .o_sound(synth_sound)
    , .o_synth_ready__(synth_ready)
    , .i_current_freq(32'(midi_req_freq))
    , .i_play(midi_note_on)
    , .i_aud_clk(i_aud_bclk)
    , .i_clk(i_clk)
    , .i_nrst(i_nrst)
    );

  // MCLK on the WM8731 Chip, Running at 12.288MHz
  logic reset_source_reset;
  AudioClocker u_audio_clocker
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

  // Audio Driver
  logic audio_init;
  logic audio_initialized;
  logic [3:0] audio_init_err_code;
  logic _unused_u_audio_initializer_manualDone;
  AudioInit u_audio_initializer
    ( .rst(i_nrst)
    , .clk(i_clk)
    , .initPulse(audio_init)
    , .SDAT(b_sdl)
    , .SDCLK(o_scl)
    , .doneInit(audio_initialized)
    , .audioInitError(audio_init_err_code)

    , .manualSend(1'b0)
    , .manualRegister(7'd0)
    , .manualData(9'd0)
    , .manualDone(_unused_u_audio_initializer_manualDone)
  );

  logic dac_done;
  logic [31:0] current_dac_data;
  assign current_dac_data = synth_sound;
  AudioDAC u_dac_drv
  ( .clk(i_clk)
  , .rst(i_nrst)
  , .AUD_BCLK(i_aud_bclk)
  , .AUD_DACLRCK(i_aud_daclrck)
  , .data(current_dac_data)
  , .done(dac_done)
  , .AUD_DACDAT(o_aud_dacdat)
  );

  // Main State Machine
  always_comb begin
    case (state)
      STATE_START: begin
        audio_init = 1'b1;
        state_next = STATE_INIT;
      end
        
      STATE_INIT: begin
        state_next = audio_initialized ? STATE_RUNNING : STATE_INIT;
        audio_init = 1'b0;
      end

      STATE_RUNNING: begin
        state_next = STATE_RUNNING;
        audio_init = 1'b0;
      end

      STATE_ERROR: begin
        state_next = STATE_ERROR;
        audio_init = 1'b0;
      end
        
      default: begin
        state_next = STATE_ERROR;
        audio_init = 1'b0;
      end
    endcase
  end

  // Helpful Output
  assign o_dbg_pins[0] = synth_ready;
  assign o_dbg_pins[1] = i_midi_inp;
  assign o_dbg_pins[2] = synth_sound[0];
  assign o_dbg_pins[3] = synth_sound[1];
  assign o_dbg_pins[4] = synth_sound[2];
  assign o_dbg_pins[5] = midi_note_on;
  assign o_dbg_pins[6] = i_aud_daclrck;
  assign o_dbg_pins[7] = i_nrst;

  mod_byte_display u_midi_middle_byte
    ( .o_lcd_upper_nibble(o_lcd7_1)
    , .o_lcd_lower_nibble(o_lcd7_0)
    , .i_value(midi_bits[15:8])
    , .i_clk(i_clk)
    , .i_nrst(i_nrst)
    );
  mod_vumeter u_vumeter(o_led_array, current_dac_data);
endmodule
