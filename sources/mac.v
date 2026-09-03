`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 09/02/2026 01:48:46 PM
// Design Name: FFN Multiply Accumulator
// Module Name: mac
// Project Name: NexysA7_SineFFN
// Target Devices: NexysA7
// Tool Versions: Vivado 2025.2
// Description: 
// 
// Dependencies: 
// 
// Revision: 0.01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mac(
                input clk100mhz,
                input rst_n,
                input signed [7:0] inp,
                input signed [7:0] weight,
                input signed [31:0] bias,
                input load,
                input acc,                         // Must be one clock pulse!!!
                output reg signed [31:0] op
          );
      
    wire signed [8:0] centered_activation;
    wire signed [16:0] product;
    
    assign centered_activation = inp + 9'sd128; 
    assign product = weight*centered_activation;
      
    always@(posedge clk100mhz or negedge rst_n) begin
        if(!rst_n) begin
            op <= 32'sd0;
        end
        else begin
            if(load) begin
                op <= bias;
            end
            else begin
                if(acc) begin
                op <= op + {{15{product[16]}}, product[16:0]};
                end
            end
        end       
    end                    
    
endmodule
