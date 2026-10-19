`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 10/19/2026 12:15:42 AM
// Design Name: Multiply Accumulator Testbench
// Module Name: mac_tb
// Project Name: NexysA7_SineFFN
// Target Devices: NexysA7
// Tool Versions: Vivado 2026.1
// Description: 
// 
// Dependencies: 
// 
// Revision: 1.3
// Revision 1.3 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mac_tb();

    logic clk;
    logic rst_n;
    logic signed [7:0] inp;
    logic signed [7:0] weight;
    logic signed [31:0] bias;
    logic load;
    logic acc;
    logic signed [31:0] op;

    int tests_run;
    int tests_passed;
    int tests_failed;
    int properties_violated;

    mac mac_dut(
                    .clk100mhz(clk),
                    .rst_n(rst_n),
                    .inp(inp),
                    .weight(weight),
                    .bias(bias),
                    .load(load),
                    .acc(acc),                       
                    .op(op)
                );

    // ---- ---- ---- ---- ---- ---- ---- ----
    //                CLOCK
    // ---- ---- ---- ---- ---- ---- ---- ----

    initial clk = 0;
    always #5 clk = ~clk;

    // ---- ---- ---- ---- ---- ---- ---- ----
    //              PROPERTIES
    // ---- ---- ---- ---- ---- ---- ---- ----

    
    property reset_clears_output;
        @(negedge clk)
        !rst_n |-> op === 32'd0;
    endproperty

    assert property (reset_clears_output)
    else begin
        $error("Output was not cleared after reset");  
        properties_violated++;
    end   

    // ---- ---- ---- ---- ---- ---- ---- ----
    //               RUN TEST
    // ---- ---- ---- ---- ---- ---- ---- ----

    task automatic run_test(
                                input logic signed [7:0] test_inp,
                                input logic signed [7:0] test_weight,
                                input logic signed [31:0] test_bias,
                                input string test_name 
                           );

        bit test_failed;
        logic signed [31:0] expected;
        expected = test_bias + ((test_inp + 128) * test_weight);

        @(negedge clk)
        inp <= test_inp;
        weight <= test_weight;
        bias <= test_bias;
        load <= 0;
        acc <= 0;

        @(negedge clk)
        load <= 1;

        @(negedge clk)
        load <= 0;
        acc <= 1;

        assert(op === load)
            else begin
                $error("Test %s: op != load after pulse", test_name);
                test_failed = 1'b1;
            end

        @(negedge clk)
        acc <= 0;

        assert(op === 1'b0)
            else begin
                $error("Test %s: op != expected", test_name);
                test_failed = 1'b1;
            end

        if(test_failed) tests_failed++;
        else tests_passed++;  

    endtask

endmodule
