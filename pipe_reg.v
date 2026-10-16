// Used for EVERY register stage in the DSP48A1 (D, A0, A1, B0, B1,
// C, OPMODE, M, CARRYIN, P, CARRYOUT)
`timescale 1ns/1ps

module pipe_reg #(
    parameter WIDTH   = 18,
    parameter REG_EN  = 1,       // 1 = real register, 0 = combinational bypass
    parameter RSTTYPE = "SYNC"   // "SYNC" or "ASYNC"
)(
    input  wire             CLK,
    input  wire             RST,
    input  wire             CE,
    input  wire [WIDTH-1:0] D,
    output reg  [WIDTH-1:0] Q
);

    generate
        if (REG_EN) begin : g_registered
            if (RSTTYPE == "ASYNC") begin : g_async
                always @(posedge CLK or posedge RST)
                    if (RST) Q <= {WIDTH{1'b0}};
                    else if (CE) Q <= D;
            end else begin : g_sync
                always @(posedge CLK)
                    if (RST) Q <= {WIDTH{1'b0}};
                    else if (CE) Q <= D;
            end
        end else begin : g_bypass
            always @(*) Q = D;
        end
    endgenerate

endmodule
