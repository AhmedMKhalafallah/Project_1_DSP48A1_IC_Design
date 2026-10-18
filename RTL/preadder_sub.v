// preadder_sub : D +/- B  (opmode[6] selects add=0 / sub=1)
`timescale 1ns/1ps

module preadder_sub (
    input  wire [17:0] D,
    input  wire [17:0] B,
    input  wire        sub,     // opmode[6]
    output wire [17:0] result
);

    assign result = sub ? (D - B) : (D + B);

endmodule
