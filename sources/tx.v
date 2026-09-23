`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 08/11/2026 02:17:10 PM
// Design Name: UART TX
// Module Name: tx
// Project Name: NexysA7_UART
// Target Devices: Nexys A7
// Tool Versions: Vivado 2025.2
// Description: 
// 
// Dependencies: 
// 
// Revision: 0.02
// Revision 0.01 - File Created
// Revision 0.02 - Updated with baud_tick
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tx(
                input clk100mhz,
                input rst_n,
                input [7:0] data_in,
                input tx_start,
                output reg tx,
                output reg tx_busy,
                output reg tx_done
         );
         
    wire baud_tick;                             
    reg [7:0] data;
    reg [2:0] idata;
    reg [1:0] state;
     
    baud_tick tick_gen(
                            .clk100mhz(clk100mhz),
                            .rst_n(rst_n),
                            .restart(1'b0),
                            .en(tx_busy),
                            .baud_tick(baud_tick),
                            .baud_half_tick()
                      ); 
    
    always@(posedge clk100mhz or negedge rst_n) begin
        if(!rst_n) begin
            state <= 2'b00;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
            data <= 8'd0;
            idata <= 3'd0;
        end
        else begin

            case(state)
                2'b00: begin: IDLE
                    tx <= 1'b1;
                    tx_done <= 1'b0; 
                    tx_busy <= 1'b0;
                     
                    if(tx_start) begin
                        tx <= 1'b0;
                        tx_busy <= 1'b1;   
                        data <= data_in;
                        state <= 2'b01;                 
                    end
                end
                
                2'b01: begin: START
                    if(baud_tick) begin
                        state <= 2'b10;
                        tx <= data[0];
                    end
                    
                end
                
                2'b10: begin: DATA
                        if(idata != 3'd7) begin
                            if(baud_tick) begin
                                idata <= idata + 3'd1;
                                tx <= data[idata + 3'd1];
                            end
                        end
                        else begin
                            if(baud_tick) begin
                                tx <= 1'b1;
                                idata <= 3'd0;
                                state <= 2'b11;
                            end
                        end
                end
                
                2'b11: begin: STOP
                    tx <= 1'b1;
                    if(baud_tick) begin 
                        state <= 2'b00;
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;
                    end
                end
                
                default: state <= 2'b00;
            endcase
        end
    end
                              
endmodule
