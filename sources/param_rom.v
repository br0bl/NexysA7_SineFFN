`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 08/31/2026 02:24:40 PM
// Design Name: Parameter ROM
// Module Name: param_rom
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


module param_rom#(
                    parameter DATA_WIDTH = 8,
                    parameter RAM_DEPTH = 16,
                    parameter ADDR_WIDTH = 4,
                    parameter MEM_FILE = ""
                 )( 
                    input clk100mhz,
                    input [ADDR_WIDTH-1:0] addr,
                    output reg signed [DATA_WIDTH-1:0] data
                );
            
    reg signed [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];    
    
    initial begin
        $readmemh(MEM_FILE, mem, 0, RAM_DEPTH-1);
    end            
    
    always@(posedge clk100mhz) begin
        data <= mem[addr];
    end
                
endmodule
