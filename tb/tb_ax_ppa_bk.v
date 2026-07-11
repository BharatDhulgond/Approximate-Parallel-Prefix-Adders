// tb_axppa_metrics.v
`timescale 1ns/1ps

module tb_axppa_metrics;
    // PARAMETERS
    parameter integer W     = 8; // adder width
    parameter integer RANGE = 8;  // 2^RANGE values per input (8 -> 256)

    // DUT inputs
    reg  [W-1:0] A;
    reg  [W-1:0] B;
    reg          cin;

    // DUT outputs for all K = 0..W
    wire [W-1:0] S_arr   [0:W];
    wire         cout_arr[0:W];

    // ----------------------------------------------------------------
    // Instantiate AxPPA for all K
    // ----------------------------------------------------------------
    genvar gv;
    generate
        for (gv = 0; gv <= W; gv = gv + 1) begin : gen_axppa
            axppa_bk #(.W(W), .K(gv)) DUT (
                .A  (A),
                .B  (B),
                .cin(cin),
                .S  (S_arr[gv]),
                .cout(cout_arr[gv])
            );
        end
    endgenerate

    // ----------------------------------------------------------------
    // Metric accumulators
    // ----------------------------------------------------------------
    // MAE = sum |err| / N      (real)
    // MRED = sum (|err|/|gold|)/N (real)
    real    abs_sum [0:W];
    real    rel_sum [0:W];
    integer max_abs[0:W];
    integer nz_cnt [0:W];

    // loop/index variables
    integer i, j, k;
    integer LIMIT;
    integer total_pairs;

    // per-sample temporaries
    integer gold;      // exact A+B+cin (fits in 32 bits)
    integer dut_full;  // {cout,S}
    integer err;
    integer abs_err;
    integer gold_abs;

    // reals for division
    real abs_real;
    real gold_real;

    // per-K report temps (MUST be declared outside the loop!)
    real MAE_tmp;
    real MRED_tmp;

    // file handle
    integer fid;

    // ----------------------------------------------------------------
    // Test procedure
    // ----------------------------------------------------------------
    initial begin
        cin         = 0;
        LIMIT       = (1 << RANGE);
        total_pairs = 0;

        // init accumulators
        for (k = 0; k <= W; k = k + 1) begin
            abs_sum[k] = 0.0;
            rel_sum[k] = 0.0;
            max_abs[k] = 0;
            nz_cnt[k]  = 0;
        end

        // open CSV
        fid = $fopen("axppa_metrics.csv", "w");
        if (fid == 0) begin
            $display("ERROR: cannot open axppa_metrics.csv for writing");
            $finish;
        end
        $fwrite(fid, "K,MAE,MRED,MaxAbsErr,NonZeroCount\n");

        $display("AxPPA metric sweep: W=%0d, RANGE=%0d, LIMIT=%0d",
                 W, RANGE, LIMIT);

        // ------------------------------------------------------------
        // Main sweep: A,B = 0..LIMIT-1
        // ------------------------------------------------------------
        for (i = 0; i < LIMIT; i = i + 1) begin
            A = i[W-1:0];
            for (j = 0; j < LIMIT; j = j + 1) begin
                B = j[W-1:0];

                #1; // allow combinational logic to settle

                total_pairs = total_pairs + 1;
                gold        = A + B + cin;
                gold_abs    = (gold < 0) ? -gold : gold;

                // per-K error accumulation
                for (k = 0; k <= W; k = k + 1) begin
                    dut_full = {cout_arr[k], S_arr[k]};
                    err      = dut_full - gold;
                    abs_err  = (err < 0) ? -err : err;

                    // sum |error|
                    abs_sum[k] = abs_sum[k] + abs_err;

                    // sum relative error |err|/|gold| (skip gold==0)
                    if (gold_abs != 0) begin
                        abs_real  = abs_err;
                        gold_real = gold_abs;
                        rel_sum[k] = rel_sum[k] + (abs_real / gold_real);
                    end

                    // track non-zero count & max error
                    if (abs_err != 0) begin
                        nz_cnt[k] = nz_cnt[k] + 1;
                        if (abs_err > max_abs[k])
                            max_abs[k] = abs_err;
                    end
                end

                if ((total_pairs % 100000) == 0)
                    $display("  processed %0d input pairs...", total_pairs);
            end
        end

        // ------------------------------------------------------------
        // Final per-K metrics and CSV write
        // ------------------------------------------------------------
        for (k = 0; k <= W; k = k + 1) begin
            MAE_tmp  = abs_sum[k] / (LIMIT * LIMIT);
            MRED_tmp = rel_sum[k] / (LIMIT * LIMIT);

            $fwrite(fid, "%0d,%0f,%0f,%0d,%0d\n",
                    k, MAE_tmp, MRED_tmp, max_abs[k], nz_cnt[k]);

            $display("K=%0d: MAE=%0f  MRED=%0f  MaxAbs=%0d  NonZero=%0d",
                     k, MAE_tmp, MRED_tmp, max_abs[k], nz_cnt[k]);
        end

        $fclose(fid);
        $display("axppa_metrics.csv written. Total pairs = %0d", total_pairs);
        $finish;
    end

endmodule
