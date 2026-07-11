`timescale 1ns/1ps

module tb_kogge_stone_axppa;

    // --------------------------------------------------------
    // Parameters (match your DUT)
    // --------------------------------------------------------
    localparam WIDTH = 16;
    localparam K     = 0;

    // --------------------------------------------------------
    // DUT I/O signals
    // --------------------------------------------------------
    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;
    reg              cin;

    wire [WIDTH-1:0] sum;
    wire             cout;

    // --------------------------------------------------------
    // Instantiate DUT
    // --------------------------------------------------------
    kogge_stone_axppa #(
        .WIDTH(WIDTH),
        .K(K)
    ) dut (
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum),
        .cout(cout)
    );

    // --------------------------------------------------------
    // Task to apply a single vector
    // --------------------------------------------------------
    task apply_test;
        input [WIDTH-1:0] ta;
        input [WIDTH-1:0] tb;
        input              tcin;
    begin
        a   = ta;
        b   = tb;
        cin = tcin;

        #1; // wait 1 ns for combinational logic to settle

        $display("TIME=%0t  A=%h  B=%h  Cin=%b  -->  SUM=%h  COUT=%b",
                 $time, a, b, cin, sum, cout);
    end
    endtask

    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------
    initial begin
        $display("===== Approx Kogge-Stone AXPPA Testbench Start =====");

        // Testcase 1
        apply_test(16'h0000, 16'h0000, 1'b0);

        // Testcase 2
        apply_test(16'h00FF, 16'h0001, 1'b0);

        // Testcase 3
        apply_test(16'h1234, 16'h4321, 1'b1);

        // Testcase 4
        apply_test(16'hABCD, 16'h1111, 1'b0);

        // Testcase 5
        apply_test(16'hFFFF, 16'h0001, 1'b0);

        $display("===== Testbench Finished =====");
        $stop;
    end

endmodule
