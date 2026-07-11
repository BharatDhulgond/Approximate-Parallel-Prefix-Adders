`timescale 1ns / 1ps

module lf_ppa_approx
#(
    parameter WIDTH = 16,
    parameter K     = 4          // number of LSBs approximated
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             cin,
    output wire [WIDTH-1:0] sum,
    output wire             cout
);

    // full LF-style tree depth
    localparam integer LEVELS = $clog2(WIDTH);

    // bitwise propagate/generate
    wire [WIDTH-1:0] p0;
    wire [WIDTH-1:0] g0;

    genvar i, l, j;

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_PRE
            assign p0[i] = a[i] ^ b[i];
            assign g0[i] = a[i] & b[i];
        end
    endgenerate

    // prefix arrays (SystemVerilog-style 2D)
    wire [WIDTH-1:0] P [0:LEVELS];
    wire [WIDTH-1:0] G [0:LEVELS];

    // level 0
    assign P[0] = p0;
    assign G[0] = g0;

    // --------------------------------------------------------
    // Modified LF prefix tree:
    //  - For bits j < K: we do NOT build long-range prefix (pass-through only)
    //  - For bits j >= K: we only combine with bits >= K
    //    i.e. if j-SHIFT < K, we treat the lower part as "neutral"
    //    so the carry for bit j depends only on bits K..j
    // --------------------------------------------------------
    generate
        for (l = 0; l < LEVELS; l = l + 1) begin : GEN_LEVEL
            localparam integer SHIFT = (1 << l);

            for (j = 0; j < WIDTH; j = j + 1) begin : GEN_COMB
                if ( (j >= SHIFT) && (j >= K) && ((j - SHIFT) >= K) ) begin
                    // Full prefix combine *only within* the accurate region [K..WIDTH-1]
                    assign P[l+1][j] = P[l][j] & P[l][j-SHIFT];
                    assign G[l+1][j] = G[l][j] |
                                       (P[l][j] & G[l][j-SHIFT]);
                end else begin
                    // Either:
                    //  - j < SHIFT  (no left partner)
                    //  - j < K      (in approximate LSB region)
                    //  - j >= K but j-SHIFT < K (would cross into LSB region)
                    // In all these cases we just pass-through the previous level.
                    assign P[l+1][j] = P[l][j];
                    assign G[l+1][j] = G[l][j];
                end
            end
        end
    endgenerate

    // --------------------------------------------------------
    // Carry and sum
    // --------------------------------------------------------
    wire [WIDTH:0] c;
    assign c[0] = cin;

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_SUM
            if (i < K) begin
                // Approximate LSB region:
                // ignore incoming carry, use only local generate
                // (you can change this rule if you want a different approx)
                assign c[i+1] = g0[i];
            end else begin
                // Accurate region:
                // carry out uses prefix result over bits K..i
                assign c[i+1] = G[LEVELS][i] | (P[LEVELS][i] & cin);
            end

            // sum bit (still uses carry-in for that bit)
            assign sum[i] = p0[i] ^ c[i];
        end
    endgenerate

    assign cout = c[WIDTH];

endmodule
