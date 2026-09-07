`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 09/06/2026 03:26:50 PM
// Design Name: Top module Sine FFN
// Module Name: top_ffn
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


module top_ffn(
                    input clk100mhz,
                    input btnc,
                    input gpio_in,
                    output gpio_out
              );
          
    
    
    wire signed [7:0] inp; 
    wire rx_error;
    wire rx_busy;
    wire rx_done;
      
    wire ffn_busy;
    wire ffn_done;
    wire signed [7:0] op;
    
    wire tx_busy;
    wire tx_done;        
          
    ffn_core sine_ffn(
                            .clk100mhz(clk100mhz),
                            .rst_n(~btnc),
                            .start(rx_done),
                            .x_q(inp),
                            .busy(ffn_busy),
                            .done(ffn_done),
                            .y_q(op)
                     );    
                          
    rx uart_rx(
                    .clk100mhz(clk100mhz),
                    .rst_n(~btnc),
                    .rx(gpio_in),
                    .rx_error(rx_error),
                    .rx_busy(rx_busy),
                    .rx_done(rx_done),
                    .data_out(inp)  
              );                         
         
    tx uart_tx(
                    .clk100mhz(clk100mhz),
                    .rst_n(~btnc),
                    .data_in(op),
                    .tx_start(ffn_done),
                    .tx(gpio_out),
                    .tx_busy(tx_busy),
                    .tx_done(tx_done)  
              );                            
  
endmodule
