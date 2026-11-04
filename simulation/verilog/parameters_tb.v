`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 09/01/2026 03:06:41 PM
// Design Name: Parametes instantiation testbench
// Module Name: parameters_tb
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


module parameters_tb();

    reg clk_tb;
    
    reg [3:0] layer1_weight_address_tb;
    reg [3:0] layer1_bias_address_tb;
    wire signed [7:0] layer1_weight_tb;
    wire signed [31:0] layer1_bias_tb;    
    
    reg [7:0] layer2_weight_address_tb;
    reg [3:0] layer2_bias_address_tb;
    wire signed [7:0] layer2_weight_tb;
    wire signed [31:0] layer2_bias_tb;     
    
    reg [3:0] layer3_weight_address_tb;
    wire signed [7:0] layer3_weight_tb;
    wire signed [31:0] layer3_bias_tb;
    
    integer i;
       
    parameters params_tb(
                            .clk100mhz(clk_tb),
    
                            .layer1_weight_address(layer1_weight_address_tb),
                            .layer1_bias_address(layer1_bias_address_tb),
                            .layer1_weight(layer1_weight_tb),
                            .layer1_bias(layer1_bias_tb),
                            
                            .layer2_weight_address(layer2_weight_address_tb),
                            .layer2_bias_address(layer2_bias_address_tb),
                            .layer2_weight(layer2_weight_tb),
                            .layer2_bias(layer2_bias_tb),
                            
                            .layer3_weight_address(layer3_weight_address_tb),
                            .layer3_weight(layer3_weight_tb),
                            .layer3_bias(layer3_bias_tb)
                        );           
                    
    initial clk_tb = 1'b0;
    always #5 clk_tb = ~clk_tb;
    
    initial begin
        layer1_bias_address_tb = 14;    // 00000D4F
        layer2_weight_address_tb = 255; // 26
        layer2_bias_address_tb = 7;     // FFFFFC9D
        layer3_weight_address_tb = 15;  // 7F
        
        for(i = 0; i < 17; i = i + 1) begin
            #1 layer1_weight_address_tb = i;
            @(posedge clk_tb);
        end
        
       $finish;     
    end                        

endmodule
