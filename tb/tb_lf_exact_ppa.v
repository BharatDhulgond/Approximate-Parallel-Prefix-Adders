`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2025 02:58:33 PM
// Design Name: 
// Module Name: tb_lf_exact_ppa
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_lf_wrapper;

    parameter WIDTH = 16;

    reg                  clk;
    reg  [WIDTH-1:0]     a;
    reg  [WIDTH-1:0]     b;
    reg                  cin;
    wire [WIDTH-1:0]     sum;
    wire                 cout;

    // Instantiate DUT
    lf_wrapper #(.WIDTH(WIDTH)) dut (
        .clk (clk),
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum),
        .cout(cout)
    );

    // Clock (10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initial values
        a   = 0;
        b   = 0;
        cin = 0;

        // Wait 1 clock edge before starting
        @(posedge clk);

        // -------------------------------
        // 5 simple test vectors
        // -------------------------------

        // Test 1
        a = 64'h0000000000000001;
        b = 64'h0000000000000001;
        cin = 0;
        @(posedge clk);

        // Test 2
        a = 64'h00000000FFFFFFFF;
        b = 64'h0000000000000001;
        cin = 0;
        @(posedge clk);

        // Test 3
        a = 64'hFFFFFFFFFFFFFFFF;
        b = 64'h0000000000000001;
        cin = 0;
        @(posedge clk);

        // Test 4
        a = 64'h123456789ABCDEF0;
        b = 64'h0FEDCBA987654321;
        cin = 1;
        @(posedge clk);

        // Test 5
        a = 64'hAAAAAAAAAAAAAAAA;
        b = 64'h5555555555555555;
        cin = 0;
        @(posedge clk);

        // Done
        #10;
        $finish;
    end

endmodule

