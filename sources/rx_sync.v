`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 08/12/2026 12:17:10 PM
// Design Name: rx synchronizer
// Module Name: rx_sync
// Project Name: NexysA7_UART
// Target Devices: Nexys A7
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


module rx_sync(
                    input clk100mhz,
                    input rst_n,
                    input in,
                    output wire synced_out,
                    output wire falling_edge
              );
                
    reg sync1;
    reg sync2;    
    reg prev;
    
    assign synced_out = sync2;
    assign falling_edge = !sync2 && prev; 
    
    always@(posedge clk100mhz or negedge rst_n) begin
        if(!rst_n) begin
            sync1 <= 1'b1;
            sync2 <= 1'b1;
            prev <= 1'b1;
        end
        else begin
            sync1 <= in;
            sync2 <= sync1;
            prev <= sync2;
        end
    end              
                
endmodule
