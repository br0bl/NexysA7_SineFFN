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
// Revision: 1.4
// Revision 1.3 - File Created
// Revision 1.4 - Testbench complete
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

    property idle_holds_output;
        @(posedge clk) disable iff (!rst_n)
        (!load && !mac_dut.product_valid) |=> op === $past(op);
    endproperty

    property load_sets_bias;
        @(posedge clk) disable iff (!rst_n)
        load |=> op === $past(bias);
    endproperty

    assert property (reset_clears_output)
        else begin
            $error("Output was not cleared after reset");  
            properties_violated++;
        end   

    assert property (idle_holds_output)
        else begin
            $error("Output changed while idle");
            properties_violated++;
        end

    assert property (load_sets_bias)
        else begin
            $error("Output did not load the bias");
            properties_violated++;
        end

    // ---- ---- ---- ---- ---- ---- ---- ----
    //             VERIFY RESET
    // ---- ---- ---- ---- ---- ---- ---- ----

    task automatic verify_reset();

        bit test_failed;
        rst_n <= 0;
        load  <= 0;
        acc   <= 0;

        repeat (2) @(negedge clk);

        assert (op == 0)
            else begin
                $error("verify reset: op != 0       op = %0d", op);
                test_failed = 1'b1;
            end

        rst_n <= 1'b1;

        tests_run++;
        if (test_failed) tests_failed++;
        else tests_passed++; 

    endtask

    // ---- ---- ---- ---- ---- ---- ---- ----
    //           RUN ACCUMULATION
    // ---- ---- ---- ---- ---- ---- ---- ----

    task automatic run_accumulation(
                                        input logic signed [7:0] test_inp [],
                                        input logic signed [7:0] test_weight [],
                                        input logic signed [31:0] test_bias,
                                        input string test_name,
                                        input int num_products
                                    );

        bit test_failed;
        logic signed [31:0] expected;
        logic signed [31:0] product;

        assert (num_products >= 0 && num_products <= test_inp.size() && num_products <= test_weight.size())
            else $fatal(1, "num_products exceeds an input array's size");

        @(negedge clk);
        bias <= test_bias;
        load <= 0;
        acc <= 0;

        @(negedge clk);
        load <= 1'b1;

        @(negedge clk);
        load <= 0;

        assert (op === test_bias)
            else begin
                $error("Test %s: op != bias after load pulse     op = %0d, bias = %0d", test_name, op, test_bias);
                test_failed = 1'b1;
            end

        expected = test_bias;

        for (int i = 0; i < num_products; i++) begin
            product = (test_inp[i] + 32'sd128) * test_weight[i];
            expected += product;

            @(negedge clk);
            inp    <= test_inp[i];
            weight <= test_weight[i];
            acc    <= 1'b1;

            @(negedge clk);
            acc <= 1'b0;

            @(negedge clk);

            assert (op === expected)
                else begin
                    $error("Test %s: op != expected     op = %0d, expected = %0d", test_name, op, expected);
                    test_failed = 1'b1;
                end

            inp    <= ~test_inp[i];
            weight <= ~test_weight[i];
            bias   <= ~test_bias;

            repeat (2) @(negedge clk);
        end

        tests_run++;
        if (test_failed) tests_failed++; 
        else tests_passed++;  

    endtask

    // ---- ---- ---- ---- ---- ---- ---- ----
    //        PIPELINED ACCUMULATION
    // ---- ---- ---- ---- ---- ---- ---- ----

    task automatic pipe_accumulation(
                                        input logic signed [7:0] test_inp [],
                                        input logic signed [7:0] test_weight [],
                                        input logic signed [31:0] test_bias,
                                        input string test_name,
                                        input int num_products
                                    );

        bit test_failed;
        logic signed [31:0] expected;
        logic signed [31:0] product;

        assert (num_products >= 0 && num_products <= test_inp.size() && num_products <= test_weight.size())
            else $fatal(1, "num_products exceeds an input array's size");

        @(negedge clk);
        load <= 1'b0;
        acc  <= 1'b0;

        @(negedge clk);
        bias <= test_bias;
        load <= 1'b1;

        @(negedge clk);
        load <= 1'b0;

        assert (op === test_bias)
            else begin
                $error("Test %s: op != bias after load pulse     op = %0d, bias = %0d", test_name, op, test_bias);
                test_failed = 1'b1;
            end

        expected = test_bias;

        for (int i = 0; i < num_products + 2; i++) begin
            @(negedge clk);

            if (i < num_products) begin
                inp    <= test_inp[i];
                weight <= test_weight[i];
                acc    <= 1'b1;
            end
            else begin
                acc <= 1'b0;
            end

            if (i >= 2) begin
                product = (test_inp[i-2] + 32'sd128) * test_weight[i-2];
                expected += product;

                assert (op === expected)
                    else begin
                        $error("Test %s, product %0d: op != expected     op = %0d, expected = %0d", test_name, i-2, op, expected);
                        test_failed = 1'b1;
                    end
            end
        end

        tests_run++;
        if (test_failed) tests_failed++;
        else tests_passed++;

    endtask

    // ---- ---- ---- ---- ---- ---- ---- ----
    //            DIRECTED TESTS
    // ---- ---- ---- ---- ---- ---- ---- ----

    task automatic directed_accumulation();

        logic signed [7:0] test_inps [];
        logic signed [7:0] test_weights [];

        test_inps    = '{-128, -128, -128, -128};
        test_weights = '{127, -128, 1, -1};

        run_accumulation(
            test_inps, test_weights, 32'sd100,
            "zero offset inputs preserve bias", test_inps.size()
        );

        pipe_accumulation(
            test_inps, test_weights, 32'sd100,
            "pipeline: zero offset inputs preserve bias", test_inps.size()
        );

        test_inps    = '{-128, -1, 0, 127};
        test_weights = '{0, 0, 0, 0};

        run_accumulation(
            test_inps, test_weights, -32'sd100,
            "zero weights preserve bias", test_inps.size()
        );

        pipe_accumulation(
            test_inps, test_weights, -32'sd100,
            "pipeline: zero weights preserve bias", test_inps.size()
        );

        test_inps    = '{-128, -64, -1, 0, 1, 64, 126, 127};
        test_weights = '{127, -128, 1, -1, 64, -64, -127, 126};

        run_accumulation(
            test_inps, test_weights, 32'sd250,
            "mixed signed operands", test_inps.size()
        );

        pipe_accumulation(
            test_inps, test_weights, 32'sd250,
            "pipeline: mixed signed operands", test_inps.size()
        );

        test_inps    = '{127, 127, -64, -64};
        test_weights = '{127, -127, 64, -64};

        run_accumulation(
            test_inps, test_weights, -32'sd50,
            "positive and negative cancellation", test_inps.size()
        );

        pipe_accumulation(
            test_inps, test_weights, -32'sd50,
            "pipeline: positive and negative cancellation", test_inps.size()
        );

        test_inps    = new[16];
        test_weights = new[16];

        foreach (test_inps[i]) begin
            test_inps[i]    = 127;
            test_weights[i] = 127;
        end

        run_accumulation(
            test_inps, test_weights, 32'sd0,
            "sixteen maximum positive products", test_inps.size()
        );

        pipe_accumulation(
            test_inps, test_weights, 32'sd0,
            "pipeline: sixteen maximum positive products", test_inps.size()
        );

        foreach (test_weights[i])
            test_weights[i] = -128;

        run_accumulation(
            test_inps, test_weights, 32'sd0,
            "sixteen maximum negative products", test_inps.size()
        );

        pipe_accumulation(
            test_inps, test_weights, 32'sd0,
            "pipeline: sixteen maximum negative products", test_inps.size()
        );

        test_inps    = '{-127};  // -127 + 128 = 1
        test_weights = '{1};

        run_accumulation(
            test_inps, test_weights, 32'sh7FFF_FFFF,
            "positive overflow", test_inps.size()
        );

        pipe_accumulation(
            test_inps, test_weights, 32'sh7FFF_FFFF,
            "pipeline: positive overflow", test_inps.size()
        );

        test_inps    = '{-127};
        test_weights = '{-1};

        run_accumulation(
            test_inps, test_weights, 32'sh8000_0000,
            "negative underflow", test_inps.size()
        );

        pipe_accumulation(
            test_inps, test_weights, 32'sh8000_0000,
            "pipeline: negative underflow", test_inps.size()
        );

        test_inps    = '{127};
        test_weights = '{-128};

        run_accumulation(
            test_inps, test_weights, 32'sd100,
            "single-product accumulation", test_inps.size()
        );

    endtask

    task automatic setup_pending_product();

        @(negedge clk);
        load <= 1'b1;
        acc  <= 1'b0;
        bias <= 32'sd100;

        @(negedge clk);
        load   <= 1'b0;
        acc    <= 1'b1;
        inp    <= 8'sd0;
        weight <= 8'sd2;

        @(negedge clk);
        acc <= 1'b0;

    endtask

    task automatic verify_control();

        bit test_failed;

        // Reset while a product is pending 
        test_failed = 1'b0;

        setup_pending_product();
        rst_n <= 1'b0;

        #1 assert (op === 32'sd0)
            else begin
                $error("Pending reset: output did not clear asynchronously");
                test_failed = 1'b1;
            end

        @(negedge clk);
        rst_n <= 1'b1;

        repeat (3) begin
            @(negedge clk);
            assert (op === 32'sd0)
                else begin
                    $error("Pending reset: expected 0, got %0d", op);
                    test_failed = 1'b1;
                end
        end

        tests_run++;
        if (test_failed) tests_failed++;
        else tests_passed++;

        // Load while a product is pending
        test_failed = 1'b0;

        setup_pending_product();
        load <= 1'b1;
        bias <= -32'sd75;

        @(negedge clk);
        load <= 1'b0;

        assert (op === -32'sd75)
            else begin
                $error("Pending load: expected -75, got %0d", op);
                test_failed = 1'b1;
            end

        repeat (2) begin
            @(negedge clk);
            assert (op === -32'sd75)
                else begin
                    $error("Pending load: expected -75 to hold, got %0d", op);
                    test_failed = 1'b1;
                end
        end

        tests_run++;
        if (test_failed) tests_failed++;
        else tests_passed++;

        // Simultaneous load and acc 
        test_failed = 1'b0;

        @(negedge clk);
        bias   <= 32'sd100;
        inp    <= 8'sd0;
        weight <= 8'sd2;
        load   <= 1'b1;
        acc    <= 1'b1;

        @(negedge clk);
        load <= 1'b0;
        acc  <= 1'b0;

        assert (op === 32'sd100)
            else begin
                $error("Simultaneous load/acc: expected bias 100, got %0d", op);
                test_failed = 1'b1;
            end

        @(negedge clk);

        assert (op === 32'sd356)
            else begin
                $error("Simultaneous load/acc: expected 356, got %0d", op);
                test_failed = 1'b1;
            end

        repeat (2) begin
            @(negedge clk);
            assert (op === 32'sd356)
                else begin
                    $error("Simultaneous load/acc: expected 356 to hold, got %0d", op);
                    test_failed = 1'b1;
                end
        end

        tests_run++;
        if (test_failed) tests_failed++;
        else tests_passed++;

    endtask

    // ---- ---- ---- ---- ---- ---- ---- ----
    //             RANDOM TESTS
    // ---- ---- ---- ---- ---- ---- ---- ----

    task automatic random_accumulation(input int iterations);

        logic signed [7:0] test_inps [];
        logic signed [7:0] test_weights [];
        logic signed [31:0] test_bias;
        int num_products;

        for (int test_id = 0; test_id < iterations; test_id++) begin
            num_products = $urandom_range(0, 64);

            test_inps    = new[num_products];
            test_weights = new[num_products];
            test_bias    = $urandom();

            foreach (test_inps[i]) begin
                test_inps[i]    = $urandom_range(0, 255);
                test_weights[i] = $urandom_range(0, 255);
            end

            run_accumulation(
                test_inps, test_weights, test_bias,
                $sformatf("random accumulation %0d", test_id),
                num_products
            );

            pipe_accumulation(
                test_inps, test_weights, test_bias,
                $sformatf("random pipeline accumulation %0d", test_id),
                num_products
            );
        end

    endtask

    // ---- ---- ---- ---- ---- ---- ---- ----
    //                 MAIN
    // ---- ---- ---- ---- ---- ---- ---- ----  

    initial begin
        tests_run = 0;
        tests_passed = 0;
        tests_failed = 0;
        properties_violated = 0;

        rst_n = 1;
        inp = 0;
        weight = 0;
        bias = 0;
        load = 0;
        acc = 0;

        verify_reset();
        directed_accumulation();
        verify_reset();
        verify_control();
        random_accumulation(1000);

        repeat (2) @(negedge clk);

        $display("--------------------------------");
        if (tests_failed === 0 && properties_violated === 0)
            $display("ALL TESTS PASSED\n");
        else
            $display("TEST(S) FAILED\n");

        $display("Tests Run: %d \nTests Passed: %d \nTests Failed: %d \nProperties Violated: %d", 
            tests_run, tests_passed, tests_failed, properties_violated);  
        $display("--------------------------------");
        
        $finish;


    end

endmodule
