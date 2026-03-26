`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Douglas Nguyen
// 
// Create Date: 03/05/2026 01:06:30 AM
// Design Name: Sound_Effect_Board
// Module Name: audio_player_top
// Target Devices: xc7a35tcpg236-1 (Basys3 Artix-7)
//
// Description: Press the buttons to make stored sounds play
// 
// Dependencies: button_debouncer.v
//////////////////////////////////////////////////////////////////////////////////

module audio_player_top(
    input clk,

    // We associate each button with a sound effect
    input btnC, //correct_sound_effect.mem
    input btnU, //faaaaah_sound_effect.mem
    input btnL, //fart_sound_effect.mem
    input btnR, //smoke_detector_beep_sound_effect.mem
    input btnD, //vine_boom_sound_effect.mem
    
    // PmodAMP2 interface
    output AUDIO_PWM,
    output AMP_GAIN,
    output AMP_SD
);

// ===========================================
// Button Debouncing
// ===========================================

wire btnC_pressed;
wire btnU_pressed;
wire btnL_pressed;
wire btnR_pressed;
wire btnD_pressed;

button_debouncer btnC_debounce (
    .clk(clk),
    .btn_noisy(btnC),
    .btn_pressed(btnC_pressed)
);

button_debouncer btnU_debounce (
    .clk(clk),
    .btn_noisy(btnU),
    .btn_pressed(btnU_pressed)
);

button_debouncer btnL_debounce (
    .clk(clk),
    .btn_noisy(btnL),
    .btn_pressed(btnL_pressed)
);

button_debouncer btnR_debounce (
    .clk(clk),
    .btn_noisy(btnR),
    .btn_pressed(btnR_pressed)
);

button_debouncer btnD_debounce (
    .clk(clk),
    .btn_noisy(btnD),
    .btn_pressed(btnD_pressed)
);

// ===========================================
// Amplifier Configuration
// ===========================================

assign AMP_GAIN = 1'b1;    // 6 dB gain high (12 dB gain low)
assign AMP_SD = 1'b1;    // Shutdown pin high for normal operation

// ===========================================
// Audio ROM Storage
// ===========================================

// sample counts determined from .wav to .mem conversion (See README for conversion process)
parameter CORRECT_LEN = 20352;
parameter FAAAAAH_LEN = 36409;
parameter FART_LEN = 32000;
parameter BEEP_LEN = 17024;
parameter BOOM_LEN = 22663;

// Store sound effect samples 
(* rom_style = "block" *) reg [7:0] correct_rom [0:CORRECT_LEN-1];
(* rom_style = "block" *) reg [7:0] faaaaah_rom [0:FAAAAAH_LEN-1];
(* rom_style = "block" *) reg [7:0] fart_rom [0:FART_LEN-1];
(* rom_style = "block" *) reg [7:0] beep_rom [0:BEEP_LEN-1];
(* rom_style = "block" *) reg [7:0] boom_rom [0:BOOM_LEN-1];

// Read .mem files
initial begin
    $readmemh("correct_sound_effect.mem", correct_rom);
    $readmemh("faaaaah_sound_effect.mem", faaaaah_rom);
    $readmemh("fart_sound_effect.mem", fart_rom);
    $readmemh("smoke_detector_beep_sound_effect.mem", beep_rom);
    $readmemh("vine_boom_sound_effect.mem", boom_rom);
end

// ===========================================
// Clock Sampling Generation
// ===========================================

parameter SAMPLE_DIV = 6250; //clk frequency (100 million Hz) / sample rate (16,000 Hz)
reg [12:0] sample_counter = 0;
reg sample_tick = 0;

always @(posedge clk) begin
    if(sample_counter == SAMPLE_DIV-1) begin
        sample_counter <= 0;
        sample_tick <= 1;
    end
    else begin
        sample_counter <= sample_counter + 1;
        sample_tick <= 0;
    end
end

// ===========================================
// Playback Control
// ===========================================

reg isPlaying = 0;
reg [2:0] sound_select = 0;   // 0 = C, 1 = U, 2 = L, 3 = R, 4 = D
reg [15:0] addr; // Max index 2^15-1 = 65,535, more than enough for each .mem sample count being used right now.
reg [7:0] current_sample;

always @(posedge clk) begin

    // Reset & Start playback when button is pressed
    if(btnC_pressed | btnU_pressed | btnL_pressed | btnR_pressed | btnD_pressed) begin
        isPlaying <= 1;
        addr <= 0;
        
        // Assume buttons will not be pressed at the same time
        if(btnC_pressed) sound_select <= 3'b000;
        else if(btnU_pressed) sound_select <= 3'b001;
        else if(btnL_pressed) sound_select <= 3'b010;
        else if(btnR_pressed) sound_select <= 3'b011;
        else if(btnD_pressed) sound_select <= 3'b100;
        else sound_select <= 3'b101; //5, nonsense value
    end

    // Case where tick occurs exactly when a button is pressed is negligible
    else if (sample_tick && isPlaying) begin
        // Update current_sample from ROM based on sound_select
        case (sound_select)
            3'b000: begin
                current_sample <= correct_rom[addr]; // Correct Sound Effect
                
                //Reset if finished, otherwise continue reading
                if(addr == CORRECT_LEN-1) begin
                    isPlaying <= 0;
                    addr <= 0;
                    sound_select <= 3'b101; // 5, nonsense value
                end
                else addr <= addr + 1;
            end
            
            3'b001: begin
                current_sample <= faaaaah_rom[addr]; // FAAAAAH Sound Effect
                
                //Reset if finished, otherwise continue reading
                if(addr == FAAAAAH_LEN-1) begin
                    isPlaying <= 0;
                    addr <= 0;
                    sound_select <= 3'b101; // 5, nonsense value
                end
                else addr <= addr + 1;
            end
            
            3'b010: begin
                current_sample <= fart_rom[addr]; // Fart Sound Effect
                
                //Reset if finished, otherwise continue reading
                if(addr == FART_LEN-1) begin
                    isPlaying <= 0;
                    addr <= 0;
                    sound_select <= 3'b101; // 5, nonsense value
                end
                else addr <= addr + 1;
            end
            
            3'b011: begin
                current_sample <= beep_rom[addr]; // Beep Sound Effect
                
                //Reset if finished, otherwise continue reading
                if(addr == BEEP_LEN-1) begin
                    isPlaying <= 0;
                    addr <= 0;
                    sound_select <= 3'b101; // 5, nonsense value
                end
                else addr <= addr + 1;
            end
            
            3'b100: begin
                current_sample <= boom_rom[addr]; // Boom Sound Effect
                
                //Reset if finished, otherwise continue reading
                if(addr == BOOM_LEN-1) begin
                    isPlaying <= 0;
                    addr <= 0;
                    sound_select <= 3'b101; // 5, nonsense value
                end
                else addr <= addr + 1;
            end
            
            // if somehow we get an invalid value, just reset
            default: begin
                isPlaying <= 0;
                addr <= 0;
                sound_select <= 3'b101; // 5, nonsense value
            end
        endcase
    end
end

// ===========================================
// PWM DAC (Send Frequencies to Amplifier)
// ===========================================

reg [7:0] pwm_counter = 0;

always @(posedge clk)
    pwm_counter <= pwm_counter + 1;
    
assign AUDIO_PWM = (pwm_counter < current_sample);

endmodule