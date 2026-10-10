timeunit 1ns;
timeprecision 1ps;

//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly Pomona
// Engineer: Ben Robles
// 
// Create Date: 09/28/2026 03:44:40 PM
// Design Name: Signed 32-bit Pipelined Multiplier Testbench
// Module Name: multiplier_32b_tb
// Project Name: NexysA7_SineFFN
// Target Devices: NexysA7
// Tool Versions: Vivado 2026.1
// Description: 
// 
// Dependencies: 
// 
// Revision: 1.02
// Revision 1.02 - File Created
// Additional Comments: First system verilog module ;)
// 
//////////////////////////////////////////////////////////////////////////////////


module multiplier_32b_tb();

    logic clk;
    logic rst_n;
    logic start;
    logic done;
    
    logic signed [31:0] operand_a;
    logic signed [31:0] operand_b;
    logic signed [63:0] product;
    
    int tests_run;
    int tests_passed;
    int tests_failed;
    
    multiplier_32b dut(
                    .clk100mhz(clk),
                    .rst_n(rst_n),
                    .start(start),
                    .done(done),
                    .A(operand_a),
                    .B(operand_b),
                    .P(product)
                 );
                 
    property valid_product;
        @(negedge clk)
        disable iff (!rst_n)
        done |-> !$isunknown(product);
    endproperty     
        
    property reset_clears_output;
        @(negedge clk)
        !rst_n |-> (done === 1'b0 && product === 64'sd0);
    endproperty
    
    logic [5:0] since_reset;
    
    always_ff @(negedge clk or negedge rst_n) begin
        if(!rst_n) since_reset <= 0;
        else since_reset <= {since_reset[4:0], 1'b1};
    end   
    
    property fixed_pipeline_latency;
        @(negedge clk)
        disable iff (!rst_n || !since_reset[5])
        done == $past(start, 5);
    endproperty
    
    assert property (valid_product)
        else $error("P is unknown when done is asserted");   
    
    assert property (fixed_pipeline_latency)
        else $error("Incorrect pipeline latency");        
    
    assert property (reset_clears_output)
        else $error("Output was not cleared after reset");     
        
    task automatic verify_reset();
        bit test_failed;
        test_failed = 1'b0;
        tests_run++;
        
        @(negedge clk);
        rst_n = 1'b0;
        start = 1'b0;
        operand_a = 32'sd128;
        operand_b = 32'sd128;

        #1 assert(done === 1'b0 && product === 64'sd0)
            else begin 
                $error("Reset is not asynchronous");
                test_failed = 1'b1;
            end
            
        for(int i = 0; i < 8; i++) begin
            @(posedge clk) #1;
            
            assert(done === 1'b0 && product === 64'sd0)
                else begin 
                    $error(1, "Pipeline failed to reset");
                    test_failed = 1'b1;
                end     
        end

        @(negedge clk);
        rst_n = 1'b1;  
        if(test_failed) tests_failed++;
        else tests_passed++;      
    endtask
    
    task automatic run_test(
                                input logic signed [31:0] test_a,
                                input logic signed [31:0] test_b,
                                input string test_name 
                           );
                               
        logic signed [63:0] extended_a;
        logic signed [63:0] extended_b;   
        logic signed [63:0] expected;
        
        bit test_failed;
        
        extended_a = $signed({{32{test_a[31]}}, test_a});
        extended_b = $signed({{32{test_b[31]}}, test_b});
        expected = extended_a * extended_b;
        
        test_failed = 1'b0;
        tests_run++;
        
        @(negedge clk);
        operand_a = test_a;
        operand_b = test_b;
        start = 1'b1;   
        
        @(negedge clk);
        start = 1'b0;

        assert(done === 1'b0)
            else begin
                $error("Test %s: done asserted early during stage 1", test_name);
                test_failed = 1'b1;
            end
        
        for(int stage = 2; stage <= 5; stage++) begin
            @(negedge clk);
            assert(done === 1'b0)
               else begin
                    $error("Test %s: done asserted early during stage %0d", test_name, stage);       
                    test_failed = 1'b1;
                end
        end
        
        @(negedge clk);
        if(done === 1'b1) begin            
            if(product !== expected) begin
                $error("Test %s: product: %0d !== expected %0d", test_name, product, expected); 
                test_failed = 1'b1;
            end
        end
        else begin
            $error("Test %s: unexpected latency", test_name);
            test_failed = 1'b1;
        end 
        
        @(negedge clk);
        assert(done === 1'b0)
            else begin
                $error("Test %s: done asserted longer than 1-cycle", test_name);
                test_failed = 1'b1;
            end
        
        if(test_failed) tests_failed++;
        else tests_passed++;                 
    endtask                           
 
    task automatic directed_tests();
        run_test(32'sd0,             32'sd0,             "both zero");
        run_test(32'sd0,            32'sd1937,          "zero operand");
        run_test(32'sd4582,         32'sd1,             "identity");
        run_test(32'sd4582,         -32'sd1,            "negation");
        run_test(32'sd52,           32'sd731,           "positive times positive");
        run_test(32'sd52,           -32'sd731,          "positive times negative");
        run_test(-32'sd52,          32'sd731,           "negative times positive");
        run_test(-32'sd52,          -32'sd731,          "negative times negative");
        run_test(32'sh7fffffff,     32'sd2,             "maximum positive");
        run_test(32'sh80000000,     32'sd1,             "minimum negative");
        run_test(32'sh80000000,     -32'sd1,            "minimum times negative one");
        run_test(32'sh80000000,     32'sh80000000,      "minimum times minimum");
        run_test(32'sh12345678,     32'sh76543210,      "large full-width product");
        run_test(32'sh55555555,     32'shaaaaaaaa,      "alternating bits");
    endtask 

    typedef struct packed {
        logic signed [31:0] a;
        logic signed [31:0] b;
        logic signed [63:0] expected;
} transaction;

task automatic random_pipeline(input int iter);
    bit test_failed;

    transaction expected_queue[$];
    transaction current;
    logic signed [63:0] extended_a, extended_b;

    test_failed = 1'b0;
    tests_run++;

    for (int cycle = 0; cycle < iter + 6; cycle++) begin
        @(negedge clk);

        if (done === 1'b1) begin
            if (expected_queue.size() == 0) begin
                $error("done asserted with no expected transaction");
                test_failed = 1'b1;
            end
            else begin
                current = expected_queue.pop_front();

                if (product !== current.expected) begin
                    $error("A=%0d B=%0d expected=%0d actual=%0d",
                           current.a, current.b, current.expected, product);
                    test_failed = 1'b1;
                end
            end
        end
        else if (done !== 1'b0) begin
            $error("done contains X or Z");
            test_failed = 1'b1;
        end

        if (cycle < iter) begin
            operand_a = $urandom;
            operand_b = $urandom;
            start = 1'b1;

            extended_a = operand_a;
            extended_b = operand_b;

            current.a = operand_a;
            current.b = operand_b;
            current.expected = extended_a * extended_b;
            expected_queue.push_back(current);
        end
        else begin
            start = 1'b0;
        end
    end

    if (expected_queue.size() != 0) begin
        $error("%0d multiplication results were never received",
               expected_queue.size());
        test_failed = 1'b1;
    end

    if (test_failed) tests_failed++;
    else             tests_passed++;
endtask
       
    initial clk = 1'b0;
    always #5 clk = ~clk;                 
    
    initial begin
        tests_run = 0;
        tests_passed = 0;
        tests_failed = 0;
        
        rst_n = 1'b1;
        start = 1'b0;
        operand_a = 32'sd0;
        operand_b = 32'sd0;
        
        verify_reset();
        directed_tests();
        random_pipeline(99);
        
        $display("Results\n--------------------------------");
        $display("Tests Run: %d \nTests Passed: %d \nTests Failed: %d", 
        tests_run, tests_passed, tests_failed);  
        $display("--------------------------------");
        
        $finish;
    end                       
endmodule
