`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2025 02:53:25 PM
// Design Name: 
// Module Name: lf_ppa_exact
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

//============================================================
// Exact Parallel Prefix Adder (LF-style) - Verilog-2001
//============================================================
module lf_ppa_exact
#(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              cin,
    output [WIDTH-1:0] sum,
    output             cout
);

    // --------------------------------------------------------
    // clog2 function for Verilog (Vivado compatible)
    // --------------------------------------------------------
    function integer clog2;
        input integer val;
        integer i;
        begin
            clog2 = 0;
            for (i = val - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    localparam LEVELS = clog2(WIDTH);

    // --------------------------------------------------------
    // Pre-processing: p0, g0
    // --------------------------------------------------------
    wire [WIDTH-1:0] p0;
    wire [WIDTH-1:0] g0;

    genvar i, l, j;

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_PRE
            assign p0[i] = a[i] ^ b[i];
            assign g0[i] = a[i] & b[i];
        end
    endgenerate

    // --------------------------------------------------------
    // Prefix arrays P[l][i], G[l][i]
    // Flattened: P_l[level][i] becomes P[level*WIDTH + i]
    // --------------------------------------------------------
    wire [(LEVELS+1)*WIDTH-1:0] P;
    wire [(LEVELS+1)*WIDTH-1:0] G;

    // Level 0 assignment
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_LEVEL0
            assign P[(0*WIDTH)+i] = p0[i];
            assign G[(0*WIDTH)+i] = g0[i];
        end
    endgenerate

    // --------------------------------------------------------
    // Prefix computation
    // --------------------------------------------------------
    generate
        for (l = 0; l < LEVELS; l = l + 1) begin : GEN_LEVEL
            localparam SHIFT = (1 << l);

            for (j = 0; j < WIDTH; j = j + 1) begin : GEN_NODE
                if (j >= SHIFT) begin
                    assign P[(l+1)*WIDTH + j] =
                        P[(l*WIDTH) + j] & P[(l*WIDTH) + (j-SHIFT)];

                    assign G[(l+1)*WIDTH + j] =
                        G[(l*WIDTH) + j] |
                       (P[(l*WIDTH) + j] & G[(l*WIDTH) + (j-SHIFT)]);
                end else begin
                    assign P[(l+1)*WIDTH + j] = P[(l*WIDTH) + j];
                    assign G[(l+1)*WIDTH + j] = G[(l*WIDTH) + j];
                end
            end
        end
    endgenerate

    // --------------------------------------------------------
    // Carry and sum generation
    // --------------------------------------------------------
    wire [WIDTH:0] c;
    assign c[0] = cin;

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_SUM
            assign c[i+1] = G[LEVELS*WIDTH + i] |
                           (P[LEVELS*WIDTH + i] & cin);
            assign sum[i] = p0[i] ^ c[i];
        end
    endgenerate

    assign cout = c[WIDTH];

endmodule

