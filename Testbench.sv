`timescale 1 us / 100 ns

module HPFIR_7_tb ();
localparam CORDIC_CLK_PERIOD = 2;
// To create 1 GHz CORDIC sampling clock
localparam FIR_CLK_PERIOD = 1000;
// To create 1 kHz FIR Lowpass filter sampling clock
localparam signed [15:0] PI_POS = 16'h 6488;
localparam signed [15:0] PI_NEG = 16'h 9B78;
// +pi in fixed-point 1.2.13
//-pi in fixed-point 1.2.13
localparam PHASE_INC_250HZ = 26; 
localparam PHASE_INC_400HZ = 42;
// Phase jump for 250Hz sine wave synthesis // Phase jump for 400Hz sine wave synthesis
reg cordic_clk = 1'b0; 
reg fir_clk = 1'b0;
reg phase_tvalid = 1'b0;
reg signed [15:0] phase_250HZ=0;
// 250Hz phase sweep, 1.2.13
reg signed [15:0] phase_400HZ = 0;
// 400Hz phase sweep. 1.2.13
wire sincos_250HZ_tvalid;
wire signed [15:0] sin_250HZ, cos_250HZ;
// 1.1.14 250Hz sine/cosine
wire sincos_400HZ_tvalid;
wire signed [15:0] sin_400HZ, cos_400HZ;
// 1.1.14 400Hz sine/cosine
reg signed [15:0] noisy_signal = 0; 
wire signed [15:0] filtered_signal;
// Resampled 250Hz sine + 400Hz sine. 1.1.14 // Filtered signal output from FIR Lowpass filter
// Synthesize 28Hz sine 
cordic_0 cordic_inst_0 (
.aclk                            (cordic_clk),
.s_axis_phase_tvalid  (phase_tvalid), 
.s_axis_phase_tdata   (phase_250HZ),
.m_axis_dout_tvalid     (sincos_250HZ_tvalid),
.m_axis_dout_tdata      ({sin_250HZ})
);

// Synthesize 30m2 sine
cordic_0 cordic_inst_1 (
.aclk                            (cordic_clk),
.s_axis_phase_tvalid  (phase_tvalid), 
.s_axis_phase_tdata   (phase_400HZ),
.m_axis_dout_tvalid     (sincos_400HZ_tvalid),
.m_axis_dout_tdata      ({sin_400HZ})
);

// Phase swe??
always @(posedge cordic_clk)
begin
    phase_tvalid <= 1'b1;
// Sweep phase to synthesize 250Hz sine
    if (phase_250HZ + PHASE_INC_250HZ < PI_POS) begin
        phase_250HZ <= phase_250HZ + PHASE_INC_250HZ;
    end else begin 
        phase_250HZ <= PI_NEG+ (phase_250HZ + PHASE_INC_250HZ - PI_POS);
    end
// Sweep phase to synthesize 400Hz sine 
    if (phase_400HZ + PHASE_INC_400HZ <= PI_POS) begin
        phase_400HZ <= phase_400HZ + PHASE_INC_400HZ;
    end else begin
        phase_400HZ <= PI_NEG + (phase_400HZ + PHASE_INC_400HZ - PI_POS);
    end
end


// Create 1 GHz Cordic clock
always begin
    cordic_clk = #(CORDIC_CLK_PERIOD/2) ~cordic_clk;
end

// Create 1 kHz FIR clock
always begin
    fir_clk = #(FIR_CLK_PERIOD/2) ~fir_clk;
end
// Noisy signal 250Hz sine + 400Hz sine
// Noisy signal is resampled at 1 kHz FIR sampling rate
always @(posedge fir_clk)
begin
    noisy_signal <= (sin_250HZ + sin_400HZ) / 2;
end
// Feed noisy signal into FIR lowpass filter
HPFIR_7 FIR_filter_inst ( 
    .clk (fir_clk), 
    .noisy_signal (noisy_signal), 
    .filtered_signal (filtered_signal)
);

//initial begin
//    // Your simulation setup code here
    
//    // Run the simulation for 1000 us (1 ms)
//    repeat (1000000) begin // 1000 us in 1 us time units
//        // Provide inputs and/or perform other operations here
        
//        #1; // Advance time by 1 time unit (1 us)
//    end
    
//    // Terminate the simulation
//    $finish;
//end
    

endmodule
