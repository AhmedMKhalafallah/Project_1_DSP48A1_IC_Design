// Computes both add and sub results
`timescale 1ns/1ps

module postadder_sub (
    input  wire [47:0] Z,
    input  wire [47:0] X,
    input  wire        CIN,
    input  wire        sub,      // opmode[7]
    output wire [47:0] result,
    output wire        carry
);

    wire [48:0] add_ext = {1'b0, Z} + {1'b0, X} + CIN;
    wire [48:0] sub_ext = {1'b0, Z} - ({1'b0, X} + CIN);

    assign result = sub ? sub_ext[47:0] : add_ext[47:0];
    assign carry  = sub ? sub_ext[48]   : add_ext[48];

endmodule
