`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 12:06:24
// Design Name: 
// Module Name: W_PPA
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

module W_PPA #(
        parameter N = 8
    )(
        input [N-1:0] a,
        input [N-1:0] b,
        input cin,
        output [N:0] fullsum
    );
        
        localparam S = $clog2(N);
        wire [N-1:0] G [S:0];
        wire [N-1:0] P [S:0];
        wire [N:0] C;
        
        assign C[0] = cin;
        assign G[0] = a & b;
        assign P[0] = a ^ b;
        
        genvar i;
        genvar j;
        
        generate
            for (i=0;i<S;i=i+1) begin
                for (j=0;j<2**i;j=j+1) begin
                    assign P[i+1][j] = P[i][j];
                    assign G[i+1][j] = G[i][j];
                end
                for (j=2**i;j<N;j=j+1) begin
                    
                    //assign P[i+1][j] = P[i][j] & P[i][j-2**i];
                    //assign G[i+1][j] = G[i][j] | (P[i][j] & G[i][j-2**i]);
                    
                    PO mypo(
                        .p1(P[i][j]),
                        .p2(P[i][j - 2**i]),
                        .g1(G[i][j]),
                        .g2(G[i][j - 2**i]),
                        .newp(P[i+1][j]),
                        .newg(G[i+1][j])
                    );
                    
                end     
            end
            for (j=1;j<=N;j=j+1) begin
                assign C[j] = (G[S][j-1] | (P[S][j-1] & cin));
            end
        endgenerate
        
        assign fullsum[N-1:0] = P[0] ^ C[N-1:0];
        assign fullsum[N] = C[N];
        
endmodule
