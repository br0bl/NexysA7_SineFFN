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
    
    task automatic verify_reset();
        bit test_failed;
        test_failed = 1'b0;
        tests_run++;
        
        @(negedge clk);
        rst_n = 1'b0;
        start = 1'b0;
        operand_a = 32'sd0;
        operand_b = 32'sd0;
        
        @(posedge clk) #1;      
        assert(done === 1'b0)
            else begin 
                $fatal(1, "Error -> reset");
                test_failed = 1'b1;
            end
            
        assert(product === 64'sd0)
            else begin 
                $fatal(1, "Error -> reset");
                test_failed = 1'b1;
            end
        
        for(int i = 0; i < 8; i++) begin
            @(posedge clk) #1;
            
            assert(done === 1'b0)
                else begin 
                    $fatal(1, "Error -> pipeline reset");
                    test_failed = 1'b1;
                end
            
            assert(product === 64'sd0)
                else begin 
                    $fatal(1, "Error -> pipeline reset");
                    test_failed = 1'b1;
                end          
        end

        @(negedge clk);
        rst_n = 1'b1;
        
        @(posedge clk);  
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
                $error("Error -> Test %s: done asserted early during stage 1", test_name);
                test_failed = 1'b1;
            end
        
        for(int stage = 2; stage <= 5; stage++) begin
            @(negedge clk);
            assert(done === 1'b0)
               else begin
                    $error("Error -> Test %s: done asserted early during stage %0d", test_name, stage);       
                    test_failed = 1'b1;
                end
        end
        
        @(negedge clk);
        if(done === 1'b1) begin            
            if(product !== expected) begin
                $error("Error -> Test %s: product: %0d !== expected %0d", test_name, product, expected); 
                test_failed = 1'b1;
            end
        end
        else begin
            $error("Error -> Test %s: unexpected latency", test_name);
            test_failed = 1'b1;
        end 
        
        if(test_failed) tests_failed++;
        else tests_passed++;               
    endtask                           
    
    multiplier_32b dut(
                        .clk100mhz(clk),
                        .rst_n(rst_n),
                        .start(start),
                        .done(done),
                        .A(operand_a),
                        .B(operand_b),
                        .P(product)
                     );
                 
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
        
        // Corner cases:
        run_test(32'sd0, 32'sd0, "Both zero");
        run_test(32'sd0, 32'sd2048, "Zero operand"); 
        run_test(32'sd1245, 32'sd1, "Identity");
    end                       
endmodule
