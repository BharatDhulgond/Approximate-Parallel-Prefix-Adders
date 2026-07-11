`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.11.2025 23:15:46
// Design Name: 
// Module Name: PO
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


module PO(
        input p1,
        input p2,
        input g1,
        input g2,
        output newp,
        output newg
    );
        assign newp = p1 & p2;
        assign newg = g1 | (p1 & g2);
endmodule
