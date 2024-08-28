/*
FIR lowpass filter with a cutoff frequency of -16MHz at 188MHz sampling rate
*/
module HPFIR_7 (
    input clk,
    input signed [15:0] noisy_signal,  
    output signed [15:0] filtered_signal  // Filtered output signal. 1.1.14
);
integer i,j;
// Coefficients for 9-tap FIR
// 10MHz cutoff frequency at 185MHz sampling rate
/*reg signed [15:0] coeff [0:6] = { 16'h 0000,
                                  16'h FDD5,
                                  16'h F956,
                                  16'h 7702,
                                  16'h F956,
                                  16'h FDD5,
                                  16'h 0000};*/
reg signed [15:0] coeff [0:6] = { 16'h 0000,
                                  16'h 04D8,
                                  16'h E747,
                                  16'h 2666,
                                  16'h E747,
                                  16'h 04D8,
                                  16'h 0000};
reg signed [15:0] delayed_signal [0:6];
reg signed [31:0] prod [0:6];
reg signed [32:0] sum_0 [0:3];
reg signed [33:0] sum_1 [0:1];
reg signed [34:0] sum_2;

always @(posedge clk)
begin
    delayed_signal[0] <= noisy_signal;  
    for (i=1;i<=6; i=i+1) begin
        delayed_signal[i] <= delayed_signal[i-1];
    end
end

// Pipelined multiply and accumulate
always @(posedge clk)
begin
    for (j=0; j<=6; j=j+1) begin
        prod[j] <= delayed_signal[j] * coeff[j];
    end
end
always @(posedge clk)
begin
    sum_0[0] <= (prod[0]+ prod[1]);
    sum_0[1] <= (prod[2]+ prod[3]);
    sum_0[2] <= (prod[4]+ prod[5]);
    sum_0[3] <= prod[6];
end
always @(posedge clk)
begin
    sum_1[0] <= (sum_0[0] + sum_0[1]);
    sum_1[1] <= (sum_0[2] + sum_0[3]);
end

always @(posedge clk)
begin
    sum_2 <= (sum_1[0] + sum_1[1]);
end
// Filtered output signal
assign filtered_signal = $signed (sum_2[34:13]);

endmodule