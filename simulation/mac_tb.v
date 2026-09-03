`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 09/02/2026 04:46:28 PM
// Design Name: FFN Multiply Accumulator Testbench
// Module Name: mac_tb
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


module mac_tb();

    reg clk_tb;
    reg rst_n_tb;
    reg signed [7:0] inp_tb;
    reg signed [7:0] weight_tb;
    reg signed [31:0] bias_tb;
    reg load_tb;
    reg acc_tb;
    wire signed [31:0] op_tb;
    
    mac mac_test (
                    .clk100mhz(clk_tb),
                    .rst_n(rst_n_tb),
                    .inp(inp_tb),
                    .weight(weight_tb),
                    .bias(bias_tb),
                    .load(load_tb),
                    .acc(acc_tb),
                    .op(op_tb)
                 );
             
    initial clk_tb = 0;
    always #5 clk_tb = ~clk_tb;
    
    initial begin
        rst_n_tb = 0;
        inp_tb = 12;
        weight_tb = -4;
        bias_tb = 20;
        #1 rst_n_tb = 1;
        
        load_tb = 1;
        @(posedge clk_tb);      // Op = 20
        #1 load_tb = 0;
        acc_tb = 1;
        @(posedge clk_tb);
        #1 acc_tb = 0;          // Op = (12+128)(-4) + 20 = -540
        
    end                 


endmodule
