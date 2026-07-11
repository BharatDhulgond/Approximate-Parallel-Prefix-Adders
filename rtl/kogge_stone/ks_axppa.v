`timescale 1ns/1ps
//============================================================
// Approximate Kogge-Stone Parallel Prefix Adder (AXPPA)
// - WIDTH : adder width
// - K     : number of LSBs using approximate logic
//
// Bit 0 is LSB, matching your Python model.
// Assumes 0 <= K < WIDTH.
//============================================================

module kogge_stone_axppa
#(
    parameter integer WIDTH = 8,
    parameter integer K     = 8  // number of approximated LSBs
)
(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             cin,   // used only when K == 0

    output wire [WIDTH-1:0] sum,
    output wire             cout
);

    // -----------------------------------------------
    // Preprocessing: bitwise propagate and generate
    // -----------------------------------------------
    wire [WIDTH-1:0] p;
    wire [WIDTH-1:0] g;

    genvar gi;
    generate
        for (gi = 0; gi < WIDTH; gi = gi + 1) begin : gen_pg
            assign p[gi] = a[gi] ^ b[gi];
            assign g[gi] = a[gi] & b[gi];
        end
    endgenerate

    // -----------------------------------------------
    // Approximate part: bits [0 .. K-1]
    //
    // S[0] = p[0]
    // S[i] = p[i] ^ g[i-1] for 1 <= i <= K-1
    // carry_in to exact part = g[K-1]  (if K > 0)
    // -----------------------------------------------
    wire [WIDTH-1:0] sum_int;
    wire             carry_in;

    generate
        if (K == 0) begin : gen_no_approx
            // No approximate region; entire adder is exact.
            assign carry_in     = cin;
        end
        else begin : gen_approx
            // K > 0: approximate K LSBs
            // bit 0
            assign sum_int[0] = p[0];

            // bits 1 .. K-1
            if (K > 1) begin : gen_approx_mid
                genvar i;
                for (i = 1; i < K; i = i + 1) begin : gen_approx_bits
                    assign sum_int[i] = p[i] ^ g[i-1];
                end
            end

            // carry into exact region from g[K-1]
            assign carry_in = g[K-1];
        end
    endgenerate

    // -----------------------------------------------
    // Exact Kogge-Stone part: bits [K .. WIDTH-1]
    // using carry_in as the "global cin".
    //
    // Prefix tree is built so that for bits in [K..],
    // only p/g from that region are combined.
    // -----------------------------------------------
    localparam integer EXACT_WIDTH = (WIDTH > K) ? (WIDTH - K) : 0;
    localparam integer LEVELS      = (EXACT_WIDTH <= 1) ? 0 : $clog2(EXACT_WIDTH);

    // Carries
    wire [WIDTH:0] C;

    // Prefix PG arrays: P[stage][bit], G[stage][bit]
    wire [WIDTH-1:0] P [0:LEVELS];
    wire [WIDTH-1:0] G [0:LEVELS];

    // Stage 0: raw p,g
    assign P[0] = p;
    assign G[0] = g;

    // Build Kogge-Stone prefix levels
    generate
        if (EXACT_WIDTH > 0) begin : gen_prefix_tree
            genvar s, j;
            for (s = 0; s < LEVELS; s = s + 1) begin : stage
                localparam integer DIST = (1 << s);
                for (j = 0; j < WIDTH; j = j + 1) begin : col
                    if (j >= (K + DIST)) begin : col_upd
                        // Combine PG across distance DIST for bits >= K
                        assign P[s+1][j] = P[s][j] & P[s][j - DIST];
                        assign G[s+1][j] = G[s][j] |
                                           (P[s][j] & G[s][j - DIST]);
                    end
                    else begin : col_passthru
                        // Bits below K+DIST remain unchanged at this stage
                        assign P[s+1][j] = P[s][j];
                        assign G[s+1][j] = G[s][j];
                    end
                end
            end
        end
    endgenerate

    // Final prefix results (if no levels, stage 0 is already final)
    wire [WIDTH-1:0] P_final;
    wire [WIDTH-1:0] G_final;

    assign P_final = P[LEVELS];
    assign G_final = G[LEVELS];

    // -----------------------------------------------
    // Carry and sum for exact region [K .. WIDTH-1]
    //
    // C[K]   = carry_in
    // C[i]   = G_final[i-1] | (P_final[i-1] & carry_in) for i > K
    // sum[i] = p[i] ^ C[i]
    // -----------------------------------------------
    generate
        if (EXACT_WIDTH > 0) begin : gen_exact_region

            // carry into first exact bit
            assign C[K] = carry_in;

            // carries for bits K+1 .. WIDTH
            genvar ci_i;
            for (ci_i = K + 1; ci_i <= WIDTH; ci_i = ci_i + 1) begin : gen_carries
                assign C[ci_i] = G_final[ci_i - 1] |
                                 (P_final[ci_i - 1] & carry_in);
            end

            // sums for bits K .. WIDTH-1
            genvar gx;
            for (gx = K; gx < WIDTH; gx = gx + 1) begin : gen_exact_sums
                assign sum_int[gx] = p[gx] ^ C[gx];
            end
        end
        else begin : gen_no_exact_region
            // No exact region (degenerate case K == WIDTH).
            // Here we just pass carry_in as cout and leave sum_int[ ] as-is.
            assign C[WIDTH:0] = { (WIDTH+1){1'b0} };
            assign C[WIDTH]   = carry_in;
        end
    endgenerate

    // -----------------------------------------------
    // Outputs
    // -----------------------------------------------
    assign sum  = sum_int;
    assign cout = (EXACT_WIDTH > 0) ? C[WIDTH] : carry_in;

endmodule
