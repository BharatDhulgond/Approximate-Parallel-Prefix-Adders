`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.11.2025 22:01:51
// Design Name: 
// Module Name: Ax_WPPA
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


module Ax_WPPA #(
        parameter N = 8,
        parameter K = 2
    )(
        input [N-1:0] a,
        input [N-1:0] b,
        input cin,
        output [N:0] fullsum
    );
        
        localparam S = $clog2(N-K);
        wire [N-1:0] G [S:0];
        wire [N-1:0] P [S:0];
        wire [N:0] C;
        
        assign C[0] = cin;
        assign G[0] = a & b;
        assign P[0] = a ^ b;
        wire carry;
        
        genvar i;
        genvar j;
        
        if (K>0) begin
            assign fullsum[0] = P[0][0];
            for (i=1; i< K - 1; i=i+1)begin
                assign fullsum[i] = P[0][i] ^ G[0][i - 1];
            end
            assign carry = G[K - 1];
        end
        else begin
            assign carry = cin;
        end
        
        if (N-K > 0) begin
            
        end
endmodule
