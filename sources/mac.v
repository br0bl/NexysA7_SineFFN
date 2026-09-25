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
// Revision: 1.1
// Revision 0.01 - File Created
// Revision 1.1 - Fixed timing error by pipelining  
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
                input acc,                       
                output reg signed [31:0] op
          );
      
    wire signed [8:0] centered_activation;
    reg signed [16:0] product;
    reg product_valid;
    
    assign centered_activation = $signed({inp[7], inp}) + 9'sd128; 
      
    always@(posedge clk100mhz or negedge rst_n) begin
        if(!rst_n) begin
            op <= 32'sd0;
            product <= 17'sd0;
            product_valid <= 1'b0;
        end
        else begin
            product_valid <= acc;
        
            if(load)
                op <= bias;
            else if(product_valid)
                op <= op + $signed({{15{product[16]}}, product});  
            
            if(acc)
                product <= weight*centered_activation;
        end       
    end                    
    
endmodule
