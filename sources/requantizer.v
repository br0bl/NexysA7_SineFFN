`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 09/02/2026 05:21:00 PM
// Design Name: Signed 32to8 Bit Requantizer
// Module Name: requantizer
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


module requantizer(
                        input clk100mhz,
                        input rst_n,
                        input signed [31:0] inp,
                        input [1:0] layer,
                        input start,
                        output reg done,
                        output reg signed [7:0] op
                  );
              
    reg [2:0] state;            
              
    reg signed [31:0] locked_inp;
    reg [1:0] locked_layer;           
    
    reg signed [31:0] multiplier;
    reg signed [31:0] zp;
    reg [3:0] right_shift;
    
    reg signed [63:0] operand;
    
    always@(*) begin
        case(locked_layer)
            2'b01: begin
                multiplier = 32'sd2039655736;
                zp = -32'sd128;
                right_shift = 4'sd7;
            end
            2'b10: begin
                multiplier = 32'sd1561796795;
                zp = -32'sd128;
                right_shift = 4'sd6;
            end
            2'b11: begin
                multiplier = 32'sd1630361836;
                zp = 32'sd5;
                right_shift = 4'sd5;
            end
            default: begin
                multiplier = 32'sd0;
                zp = 32'sd0;
                right_shift = 4'sd0;
            end
        endcase
    end
          
    always@(posedge clk100mhz or negedge rst_n) begin
        if(!rst_n) begin
            done <= 0;
            op <= 8'sd0;
            state <= 3'b000;
            locked_inp <= 0;
            locked_layer <= 0;
            operand <= 0;
        end
        else begin
            case(state)
                3'b000: begin: START
                    done <= 0;
                    if(start) begin
                        locked_inp <= inp;
                        locked_layer <= layer;
                        state <= 3'b001; 
                    end
                end
                3'b001: begin: EFFECTIVE_MULTIPLIER
                    operand <= locked_inp*multiplier;
                    state <= 3'b010;
                end
                3'b010: begin: ROUNDING
                    operand <= (operand + 64'sd1073741824) >>> 31;                                                      // Nudge and Divide by 2^31
                    state <= 3'b011;
                end
                3'b011: begin: DOUBLE_ROUNDING
                    if(operand >= 64'sd0) operand <= (operand + (64'sd1 << (right_shift - 4'd1))) >>> right_shift;      // Nudge and Divide by 2^k
                    else operand <= (operand + ((64'sd1 << (right_shift - 4'd1)) - 64'sd1)) >>> right_shift;
                    state <= 3'b100;
                end
                3'b100: begin: ZERO_POINT
                    operand <= operand + zp;
                    state <= 3'b101;
                end
                3'b101: begin: SATURATION
                    if(operand > 64'sd127) operand <= 64'sd127;
                    else if (operand < -64'sd128) operand <= -64'sd128;
                    state <= 3'b110;
                end
                3'b110: begin: END
                    op <= operand[8:0];
                    done <= 1;
                    state <= 3'b000;
                end
                default: state <= 3'b000;
            endcase
        end
    end    
                      
endmodule
