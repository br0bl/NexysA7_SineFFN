`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 08/07/2026 12:18:19 AM
// Design Name: Baud tick generator
// Module Name: baud_tick
// Project Name: NexysA7_UART
// Target Devices: Nexys A7
// Tool Versions: Vivado 2025.2
// Description: 
// 
// Dependencies: 
// 
// Revision: 0.04
// Revision 0.01 - File Created
// Revision 0.02 - Fixes
// Revision 0.03 - Half tick gen
// Revision 0.04 - Synthesis fix
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module baud_tick#(parameter baud_rate = 115200) 
                (
                    input clk100mhz,
                    input rst_n,
                    input restart,
                    input en,
                    output wire baud_tick,
                    output wire baud_half_tick
                );
                
    localparam cycles = 100_000_000/baud_rate;        
    reg [$clog2(cycles)-1:0] counter;
    
    assign baud_tick = en && (counter == (cycles - 1));
    assign baud_half_tick = en && (counter == (cycles - 1)/2);
        
    always@(posedge clk100mhz or negedge rst_n) begin
        if(!rst_n) counter <= 0;
        else begin
            if(!en || restart) counter <= 0;
            else begin
                if(baud_tick) counter <= 0;
                else counter <= counter + 1;  
            end
        end
    end                     
               
endmodule
