`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 09/24/2026 02:21:26 PM
// Design Name: Signed 32-bit Pipelined Multiplier
// Module Name: multiplier_32b
// Project Name: NexysA7_SineFFN
// Target Devices: NexysA7
// Tool Versions: Vivado 2026.1
// Description: 
// 
// Dependencies: 
// 
// Revision: 1.1
// Revision 1.1 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module multiplier_32b(
                        input clk100mhz,
                        input signed [31:0] A,
                        input signed [31:0] B,                      
                        input start,
                        input rst_n,
                        output wire done,
                        output reg signed [63:0] P
                     );
                 
   reg signed [16:0] A_H, A_L, B_H, B_L;
   reg signed [33:0] P_LL, P_LH, P_HL, P_HH;    // Partial products
   reg signed [34:0] P_X;                       // Cross product
   
   reg signed [33:0] P_LL_S3, P_HH_S3;          // Stage
   reg signed [33:0] P_HH_S4;                   // De
   reg signed [63:0] P_S5;                      // lays
   
   reg signed [63:0] LowMiddle;                 // Low/Middle Merge
   
   reg [5:0] valid_pipe;
   
   assign done = valid_pipe[5];
   
   always@(posedge clk100mhz or negedge rst_n) begin
    if(!rst_n) begin
        A_H <= 17'd0;
        A_L <= 17'd0;
        B_H <= 17'd0;
        B_L <= 17'd0;
        P_LL <= 34'd0;
        P_LH <= 34'd0;
        P_HL <= 34'd0;
        P_HH <= 34'd0;
        P_X <= 35'd0;
        P_LL_S3 <= 34'd0;
        P_HH_S3 <= 34'd0;
        P_HH_S4 <= 34'd0;
        LowMiddle <= 64'd0;
        valid_pipe <= 6'd0;
        P_S5 <= 64'd0;
        P <= 64'sd0;

    end
    else begin
        valid_pipe <= {valid_pipe[4:0], start};
    
        // Stage 1: Capture input
        A_H <= {A[31], A[31:16]};   // Signed
        A_L <= {1'b0, A[15:0]};     // Unsigned
        B_H <= {B[31], B[31:16]};
        B_L <= {1'b0, B[15:0]};
        
        // Stage 2: Partial products
        P_LL <= A_L * B_L;
        P_LH <= A_L * B_H;
        P_HL <= A_H * B_L;
        P_HH <= A_H * B_H;
        
        // Stage 3: Cross product
        P_LL_S3 <= P_LL;
        P_HH_S3 <= P_HH;
        
        P_X <= $signed({P_HL[33], P_HL}) +      // Sign extend P_HL
               $signed({P_LH[33], P_LH});       // Sign extend P_LH
        
        // Stage 4: Merge middle & low
        P_HH_S4 <= P_HH_S3;
        
        LowMiddle <= $signed({{30{1'b0}}, P_LL_S3}) +           // Zero extend P_LL
                     ($signed({{29{P_X[34]}}, P_X}) <<< 16);    // Sign extend P_X
        
        // Stage 5: Merge high and LowMiddle
        P_S5 <= LowMiddle +
                ($signed({{30{P_HH_S4[33]}}, P_HH_S4}) <<< 32);
        
        // Stage 6: Output
        P <= P_S5; 
    end 
   end   
                        
endmodule
