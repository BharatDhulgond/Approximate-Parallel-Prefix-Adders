`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.11.2025 16:45:42
// Design Name: 
// Module Name: Tb_WPPA
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


module Tb_WPPA();
    parameter W = 16;
    reg [W-1:0] num1;
    reg [W-1:0] num2;
    reg Cin;
    wire [W:0] sum;
    
    W_PPA #(
        .N(W)
    )uut (
        .a(num1),
        .b(num2),
        .cin(Cin),
        .fullsum(sum)
    );
    
    integer i, j, answer, error;
    
    always @(*) begin
        error <= sum - answer;
    end
    
    initial begin
        $monitor("time = %0t, num1 = %d, num2 = %d, sum = %d, ans = %d, error = %d", $time, num1, num2, sum, answer, error);
       
        for (i=0; i<2**(W-1); i=i+1) begin
            for (j=0; j<2**(W-1); j=j+1) begin
                Cin = 0;
                num1 = i;
                num2 = j;
                answer = i + j + Cin;
                #0.00025;
                Cin = 1;
                answer = i + j + Cin;
                #0.00025;
            end
        end
        $finish;
    end
endmodule

