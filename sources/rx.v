`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 08/12/2026 11:44:13 AM
// Design Name: UART RX
// Module Name: rx
// Project Name: NexysA7_UART
// Target Devices: Nexys A7
// Tool Versions: Vivado 2025.2
// Description:
// 
// Dependencies: 
// 
// Revision: 0.02
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rx(
                input clk100mhz,
                input rst_n,
                input rx,
                output reg rx_busy,
                output reg rx_done,
                output reg rx_error,
                output reg [7:0] data_out
         );
     
    wire baud_tick;
    wire baud_half_tick;
    wire restart_timer;
    
    wire rx_fallen_edge;
    wire rx_synced;
        
    reg [1:0] state;
    reg [7:0] data;
    reg [2:0] idata;
    
    assign restart_timer = (state == 2'b01) && baud_half_tick && !rx_synced;
    
    baud_tick two_tick_gen(
                                .clk100mhz(clk100mhz),
                                .rst_n(rst_n),
                                .restart(restart_timer),
                                .en(rx_busy),
                                .baud_tick(baud_tick),
                                .baud_half_tick(baud_half_tick)
                          );
                      
    rx_sync synchronizer(
                            .clk100mhz(clk100mhz),
                            .rst_n(rst_n),
                            .in(rx),
                            .synced_out(rx_synced),
                            .falling_edge(rx_fallen_edge)
                        );
                                               
    always@(posedge clk100mhz or negedge rst_n) begin
        if(!rst_n) begin
            state <= 2'b00;
            data <= 8'd0;
            idata <= 3'd0;
            
            rx_busy <= 1'b0;
            rx_done <= 1'b0;
            rx_error <= 1'b0;
            data_out <= 8'd0;
        end
        else begin
            case(state)
                2'b00: begin: IDLE
                    rx_busy <= 1'b0;
                    rx_done <= 1'b0;
                    rx_error <= 1'b0;
                    
                    if(rx_fallen_edge) begin
                        rx_busy <= 1'b1;
                        idata <= 3'd0;
                        state <= 2'b01;
                    end
                end
                
                2'b01: begin: START
                    if(baud_half_tick) begin
                        if(!rx_synced) begin
                            state <= 2'b10;
                            data <= 8'd0;
                        end
                        else begin
                            state <= 2'b00;
                            rx_busy <= 1'b0;
                        end
                    end 
                end
                
                2'b10: begin: DATA
                    if(baud_tick) begin
                        data[idata] <= rx_synced;
                        if(idata != 3'd7) idata <= idata + 3'd1;
                        else state <= 2'b11;
                    end
                end
                
                2'b11: begin: STOP
                    if(baud_tick) begin
                        if(rx_synced) begin
                            data_out <= data;
                            rx_done <= 1'b1;
                            rx_busy <= 1'b0;
                            state <= 2'b00;
                        end
                        else begin
                            rx_error <= 1'b1;
                            rx_busy <= 1'b0;
                            state <= 2'b00;
                        end
                    end
                end
                
                default: state <= 2'b00;
            endcase
        end   
    end                    
                                       
endmodule