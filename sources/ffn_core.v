`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 09/5/2026 12:30:38 PM
// Design Name: Sine FFN Core
// Module Name: ffn_core
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

module ffn_core(
                            input clk100mhz,
                            input rst_n,
                            input start,
                            input signed [7:0] x_q,
                            output reg busy,
                            output reg done,
                            output reg signed [7:0] y_q
                     );

    reg [3:0] layer1_weight_address;
    reg [3:0] layer1_bias_address;
    reg [7:0] layer2_weight_address;
    reg [3:0] layer2_bias_address;
    reg [3:0] layer3_weight_address;   
    
    wire signed [7:0] layer1_weight;
    wire signed [31:0] layer1_bias;
    wire signed [7:0] layer2_weight;
    wire signed [31:0] layer2_bias;
    wire signed [7:0] layer3_weight;
    wire signed [31:0] layer3_bias;  

    parameters init_rom(
                            .clk100mhz(clk100mhz),
    
                            .layer1_weight_address(layer1_weight_address),
                            .layer1_bias_address(layer1_bias_address),
                            .layer1_weight(layer1_weight),
                            .layer1_bias(layer1_bias),
    
                            .layer2_weight_address(layer2_weight_address),
                            .layer2_bias_address(layer2_bias_address),
                            .layer2_weight(layer2_weight),
                            .layer2_bias(layer2_bias),
    
                            .layer3_weight_address(layer3_weight_address),
                            .layer3_weight(layer3_weight),
                            .layer3_bias(layer3_bias)                                                
                       );

    reg signed [7:0] mac_in;
    reg signed [7:0] weight_in;
    reg signed [31:0] bias_in; 
    reg load_mac;
    reg acc_mac;
    wire signed [31:0] mac_out;               

    mac  init_mac(
                    .clk100mhz(clk100mhz),
                    .rst_n(rst_n),
                    .inp(mac_in),
                    .weight(weight_in),
                    .bias(bias_in),
                    .load(load_mac),
                    .acc(acc_mac),
                    .op(mac_out)
                 );  

    wire signed [31:0] requant_in;
    reg [1:0] layer_index;
    reg requant_start;
    wire requant_done;
    wire signed [7:0] requant_out;      
    
    assign requant_in = mac_out;         

    requantizer init_requant(
                                .clk100mhz(clk100mhz),
                                .rst_n(rst_n),
                                .inp(requant_in),
                                .layer(layer_index),
                                .start(requant_start),
                                .done(requant_done),
                                .op(requant_out)
                            );   

    reg [3:0] state;
    reg signed [7:0] locked_x;
    reg signed [7:0] layer1_activations [0:15];
    reg signed [7:0] layer2_activations [0:15];
    reg [3:0] neuron_index;
    reg [3:0] tap_index;
        
    always@(*) begin
        layer1_weight_address = 4'd0;
        layer1_bias_address = 4'd0;
        layer2_weight_address = 8'd0;
        layer2_bias_address = 4'd0;
        layer3_weight_address = 4'd0;
        weight_in = 4'd0;
        bias_in = 32'd0;
        mac_in = 8'd0;
        
        case(layer_index) 
            2'b01: begin
                layer1_weight_address = neuron_index;
                layer1_bias_address = neuron_index;
                weight_in = layer1_weight;
                bias_in = layer1_bias;
                mac_in = locked_x;
            end   
            2'b10: begin
                layer2_weight_address = 16*neuron_index + tap_index;
                layer2_bias_address = neuron_index;
                weight_in = layer2_weight;
                bias_in = layer2_bias;
                mac_in = layer1_activations[tap_index];
            end
            2'b11: begin
                layer3_weight_address = tap_index;
                weight_in = layer3_weight;
                bias_in = layer3_bias;
                mac_in = layer2_activations[tap_index];
            end     
        endcase
    end

    always@(posedge clk100mhz or negedge rst_n) begin
        if(!rst_n) begin
            load_mac <= 1'b0;
            acc_mac <= 1'b0;
           
            requant_start <= 1'b0;

            state <= 4'd0;
            locked_x <= 8'sd0;
            neuron_index <= 4'd0;
            layer_index <= 2'd0;
            tap_index <= 4'd0;
            
            busy <= 1'b0;
            done <= 1'b0;
            y_q <= 8'sd0;
        end    
        else begin
            case(state)
                4'd0: begin: IDLE
                    done <= 1'b0;
                    if(start) begin
                        locked_x <= x_q;
                        layer_index <= 2'b01;
                        neuron_index <= 4'd0;
                        tap_index <= 4'd0;
                        busy <= 1'b1; 
                        state <= 4'd1; 
                    end
                end
                4'd1: begin: ROM_WAIT
                    state <= 4'd2;
                end                
                4'd2: begin: LOAD_BIAS
                    load_mac <= 1'b1;
                    state <= 4'd3;
                end
                4'd3: begin: MAC_WAIT     
                    load_mac <= 1'b0;
                    state <= 4'd4;
                end
                4'd4: begin: ACCUMULATE
                    acc_mac <= 1'b1;
                    state <= 4'd5;
                end
                4'd5: begin: TAP_CHECK
                    acc_mac <= 1'b0;
                    if(layer_index > 1) begin
                        if(tap_index < 4'd15) begin
                            tap_index <= tap_index + 4'd1;
                            state <= 4'd3;
                        end    
                        else state <= 4'd6;
                    end
                    else state <= 4'd6;
                end
                4'd6: begin: START_REQUANT
                    requant_start <= 1'b1;
                    state <= 4'd7;
                end
                4'd7: begin: WAIT_REQUANT
                    requant_start <= 1'b0;
                    if(requant_done) state <= 4'd8;
                end
                4'd8: begin: STORE_RESULT
                    case(layer_index) 
                        2'd1: begin
                            layer1_activations[neuron_index] <= requant_out; 
                            state <= 4'd9;
                        end
                        2'd2: begin
                            layer2_activations[neuron_index] <= requant_out;
                            state <= 4'd9;
                        end
                        2'd3: begin
                            y_q <= requant_out;
                            state <= 4'd9;
                        end
                        default: state <= 4'd9;
                    endcase
                end
                4'd9: begin: NEURON_CHECK
                    if(layer_index < 2'd3) begin
                        if(neuron_index < 4'd15) begin
                            neuron_index <= neuron_index + 4'd1;
                            tap_index <= 4'd0;
                            state <= 4'd1;
                        end
                        else begin
                            layer_index <= layer_index + 2'd1;
                            neuron_index <= 4'd0;
                            tap_index <= 4'd0;
                            state <= 4'd1;
                        end   
                    end
                    else state <= 4'd10;
                end
                4'd10: begin: DONE
                    load_mac <= 1'b0;
                    acc_mac <= 1'b0;
                    requant_start <= 1'b0;
                    state <= 4'd0;
                    locked_x <= 8'sd0;
                    neuron_index <= 4'd0;
                    layer_index <= 2'd0;
                    tap_index <= 4'd0;
                    busy <= 1'b0;
                    done <= 1'b1;
                end
                default: begin
                    load_mac <= 1'b0;
                    acc_mac <= 1'b0;
                    requant_start <= 1'b0;
                    state <= 4'd0;
                    locked_x <= 8'sd0;
                    neuron_index <= 4'd0;
                    layer_index <= 2'd0;
                    tap_index <= 4'd0;
                    busy <= 1'b0;
                    done <= 1'b0;
                    y_q <= 8'sd0;
                end
            endcase
        end
    end
                                                            
endmodule