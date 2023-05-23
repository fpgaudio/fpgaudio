//Created by Austyn Larkin 2016
//All rights reserved


module fpgaudio
(input rst, 
input clk,


output AUD_XCK,
input AUD_BCLK,
output AUD_DACDAT,
input AUD_DACLRCK,


inout SDAT, 
output SDCLK, 
output [0:6] ss1,
output [0:6] ss2,
output [15:0]redLEDs);



//Audio Clock (12.288Mhz)
wire audioClk;
wire reset_source_reset;
AudioClocker myAudioClocker(
    .audio_clk_clk(audioClk),      //    audio_clk.clk
    .ref_clk_clk(clk),        //      ref_clk.clk
    .ref_reset_reset(rst),    //    ref_reset.reset
    .reset_source_reset(reset_source_reset)  // reset_source.reset
);

assign AUD_XCK = audioClk;//1'bz;

//STATE MACHINE

localparam STATE_START = 4'd0;
localparam STATE_INIT = 4'd1;
localparam STATE_RUNNING = 4'd2;
localparam STATE_ERROR = 4'd3;

reg [3:0]s;
reg [3:0]ns;

initial s = STATE_START;

always @ (posedge clk or negedge rst)
begin
    if(rst == 1'b0)
    begin
        s <= STATE_START;
    end
    else
    begin
        s <= ns;
    end

end



//TALKING TO AUDIO CHIP AND AUDIO CHIP STATE_INITIALIZATION.
reg audioInitPulse;
wire audioDoneInit;
wire [3:0]audioInitError;
wire [3:0] audioInitErrorNotI2c;

wire _unused_myAudioInit_manualDone;
AudioInit myAudioInit(
.rst(rst),
.clk(clk),
.initPulse(audioInitPulse),
.SDAT(SDAT),//i2c data line
.SDCLK(SDCLK),//i2c clock out.
.doneInit(audioDoneInit),//Goes high when the module is done doing its thing
.audioInitError(audioInitError),

.manualSend(1'b0),//Pulse high to send i2c data manually.
.manualRegister(7'd0),
.manualData(9'd0),
.manualDone(_unused_myAudioInit_manualDone)
);
//END TALKING TO AUDIO CHIP SECTION.


//ADC AND DAC
wire DACDone;
reg [31:0]currentDACData;
initial currentDACData = 32'd0;


always @(posedge clk) begin
  currentDACData <= currentDACData + 1000;
end

AudioDAC myDAC(
.clk(clk),//50Mhz
.rst(rst),//reset
.AUD_BCLK(AUD_BCLK),//Audio chip clock
.AUD_DACLRCK(AUD_DACLRCK),//Will go high when ready for data.
.data(currentDACData),//The full data we want to send.

.done(DACDone),//Pulses high on done
.AUD_DACDAT(AUD_DACDAT)//The data to send out on each pulse.
);

always @ (*) 
begin
    audioInitPulse = 1'b0;
    
    case(s)
      STATE_START: begin
        audioInitPulse = 1'b1;
        ns = STATE_INIT;    
      end
        
      STATE_INIT: begin
        ns = audioDoneInit ? STATE_RUNNING : STATE_INIT;
		end

      STATE_RUNNING: begin
        ns = STATE_RUNNING;
      end

      STATE_ERROR: begin
        ns = STATE_ERROR;
      end
        
      default: begin
        ns = STATE_ERROR;
      end
    
    endcase
end
//STATE MACHINE END

//Output the current state to the seven segment
mod_7seg u_global_state(ss1, s[3:0]);
mod_7seg u_i2c_err_code(ss2, audioInitError);
mod_vumeter u_vumeter(redLEDs, currentDACData);

endmodule
