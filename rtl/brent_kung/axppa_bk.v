`timescale 1ns/1ps
module axppa_bk
#(
    parameter integer W = 16,
    parameter integer K = 16
)
(
    input  wire [W-1:0] A,
    input  wire [W-1:0] B,
    input  wire         cin,
    output wire [W-1:0] S,
    output wire         cout
);

    // safe LEVELS (at least 1)
    localparam integer LEVELS = ($clog2(W) == 0) ? 1 : $clog2(W);

    // bitwise propagate/generate
    wire [W-1:0] p0;
    wire [W-1:0] g0;
    genvar i, j;
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_pg
            assign p0[i] = A[i] ^ B[i];
            assign g0[i] = A[i] & B[i];
        end
    endgenerate

    // Carry vector (C[i] is carry into bit i). C[0]=cin
    wire [W:0] C;
    assign C[0] = cin;

    // Approximate carries for i = 1..min(K,W)
    generate
        if (K > 0) begin : approx_carries
            // note: if K > W, we only need up to W
            localparam integer LIM = (K > W) ? W : K;
            for (i = 1; i <= LIM; i = i + 1) begin : gen_c_approx
                assign C[i] = g0[i-1];
            end
        end
    endgenerate

    // Prefix arrays for exact region (0..LEVELS)
    wire [W-1:0] p_lvl [0:LEVELS];
    wire [W-1:0] g_lvl [0:LEVELS];

    // level 0 = p0/g0
    generate
        for (i = 0; i < W; i = i + 1) begin : lvl0
            assign p_lvl[0][i] = p0[i];
            assign g_lvl[0][i] = g0[i];
        end
    endgenerate

    // iterative doubling BUT only combine when both indices are >= K
    generate
        for (j = 1; j <= LEVELS; j = j + 1) begin : lvl
            localparam integer dist = (1 << (j-1));
            for (i = 0; i < W; i = i + 1) begin : nodes
                if ((i >= K) && ((i - dist) >= K)) begin
                    assign p_lvl[j][i] = p_lvl[j-1][i] & p_lvl[j-1][i - dist];
                    assign g_lvl[j][i] = g_lvl[j-1][i] | (p_lvl[j-1][i] & g_lvl[j-1][i - dist]);
                end else begin
                    assign p_lvl[j][i] = p_lvl[j-1][i];
                    assign g_lvl[j][i] = g_lvl[j-1][i];
                end
            end
        end
    endgenerate

    // carry into exact region
    wire carryr;
    generate
        if (K == 0) begin : no_approx
            assign carryr = cin;
        end else if (K >= W) begin : all_approx
            // if fully approximate, just use the top generate (g0[W-1])
            assign carryr = g0[W-1];
        end else begin : has_approx
            assign carryr = g0[K-1];
        end
    endgenerate

    // compute exact-region carries: for i = K..W-1 set C[i+1]
    generate
        if (K < W) begin : compute_exact_carries
            for (i = K; i < W; i = i + 1) begin : gen_c_exact
                assign C[i+1] = g_lvl[LEVELS][i] | (p_lvl[LEVELS][i] & carryr);
            end
        end
    endgenerate

    // Final sums: S[i] = p0[i] ^ C[i] for all i
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_sum
            assign S[i] = p0[i] ^ C[i];
        end
    endgenerate

    // final carry-out
    assign cout = C[W];

endmodule
