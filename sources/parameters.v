`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 09/01/2026 02:19:45 PM
// Design Name: Parameters instantiation
// Module Name: parameters
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


module parameters(
                    input clk100mhz,
                    
                    input [3:0] layer1_weight_address,
                    input [3:0] layer1_bias_address,
                    output wire signed [7:0] layer1_weight,
                    output wire signed [31:0] layer1_bias,
                    
                    input [7:0] layer2_weight_address,
                    input [3:0] layer2_bias_address,
                    output wire signed [7:0] layer2_weight,
                    output wire signed [31:0] layer2_bias,
                    
                    input [3:0] layer3_weight_address,
                    output wire signed [7:0] layer3_weight,
                    output wire signed [31:0] layer3_bias
                 );      
                 
    // Weight ROM               
    
    param_rom#(
                .DATA_WIDTH(8), 
                .RAM_DEPTH(16),  
                .ADDR_WIDTH(4),
                .MEM_FILE("layer1_weights.mem")               
              ) 
    layer1_weight_rom(
                        .clk100mhz(clk100mhz),
                        .addr(layer1_weight_address),
                        .data(layer1_weight)
                     );
                  
    param_rom#(
                .DATA_WIDTH(8), 
                .RAM_DEPTH(256),  
                .ADDR_WIDTH(8),
                .MEM_FILE("layer2_weights.mem")               
              ) 
    layer2_weight_rom(
                        .clk100mhz(clk100mhz),
                        .addr(layer2_weight_address),
                        .data(layer2_weight)
                     );      
                      
    param_rom#(
                .DATA_WIDTH(8), 
                .RAM_DEPTH(16),  
                .ADDR_WIDTH(4),
                .MEM_FILE("layer3_weights.mem")               
              ) 
    layer3_weight_rom (
                        .clk100mhz(clk100mhz),
                        .addr(layer3_weight_address),
                        .data(layer3_weight)
                      );  
                  
    // Bias ROM
    
    param_rom#(
                .DATA_WIDTH(32), 
                .RAM_DEPTH(16),  
                .ADDR_WIDTH(4),
                .MEM_FILE("layer1_bias.mem")               
              ) 
    layer1_bias_rom (
                        .clk100mhz(clk100mhz),
                        .addr(layer1_bias_address),
                        .data(layer1_bias)
                    );
                  
    param_rom#(
                .DATA_WIDTH(32), 
                .RAM_DEPTH(16),  
                .ADDR_WIDTH(4),
                .MEM_FILE("layer2_bias.mem")               
              ) 
    layer2_bias_rom (
                        .clk100mhz(clk100mhz),
                        .addr(layer2_bias_address),
                        .data(layer2_bias)
                      );      
                      
    param_rom#(
                .DATA_WIDTH(32), 
                .RAM_DEPTH(1),  
                .ADDR_WIDTH(1),
                .MEM_FILE("layer3_bias.mem")               
              ) 
    layer3_bias_rom (
                        .clk100mhz(clk100mhz),
                        .addr(1'b0),
                        .data(layer3_bias)
                      );                                                                     
                            
endmodule
