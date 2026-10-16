`timescale 1ns/1ps

module DSP48A1 #(
    parameter A0REG        = 0,
    parameter A1REG        = 1,
    parameter B0REG        = 0,
    parameter B1REG        = 1,
    parameter CREG         = 1,
    parameter DREG         = 1,
    parameter MREG         = 1,
    parameter PREG         = 1,
    parameter CARRYINREG   = 1,
    parameter CARRYOUTREG  = 1,
    parameter OPMODEREG    = 1,
    parameter CARRYINSEL   = "OPMODE5",
    parameter B_INPUT      = "DIRECT",
    parameter RSTTYPE      = "SYNC"
)(
    input  wire [17:0] A,
    input  wire [17:0] B,
    input  wire [17:0] D,
    input  wire [47:0] C,
    input  wire        CLK,
    input  wire        CARRYIN,
    input  wire [7:0]  OPMODE,
    input  wire [17:0] BCIN,
    input  wire [47:0] PCIN,

    input  wire RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE,
    input  wire CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE,

    output wire [17:0] BCOUT,
    output wire [47:0] PCOUT,
    output wire [47:0] P,
    output wire [35:0] M,
    output wire         CARRYOUT,
    output wire         CARRYOUTF
);
    // Internal wires between pipeline stages
    wire [17:0] b_src;
    wire [17:0] d_reg_out;
    wire [17:0] a0_reg_out, a1_reg_out;
    wire [17:0] b0_reg_out, b1_reg_out, b1_in;
    wire [17:0] preadd_result;
    wire [47:0] c_reg_out;
    wire [7:0]  opmode_use;
    wire [35:0] mult_result, m_out;
    wire        cyi_in, cin_final;
    wire        post_carry;
    wire [47:0] x_val, z_val, post_result, p_reg_out;

    // B input source (DIRECT vs CASCADE)
    assign b_src = (B_INPUT == "CASCADE") ? BCIN : B;

    // Stage 1 registers
    pipe_reg #(.WIDTH(18), .REG_EN(DREG), .RSTTYPE(RSTTYPE))
        u_dreg (.CLK(CLK), .RST(RSTD), .CE(CED), .D(D), .Q(d_reg_out));

    pipe_reg #(.WIDTH(18), .REG_EN(A0REG), .RSTTYPE(RSTTYPE))
        u_a0reg (.CLK(CLK), .RST(RSTA), .CE(CEA), .D(A), .Q(a0_reg_out));

    pipe_reg #(.WIDTH(18), .REG_EN(A1REG), .RSTTYPE(RSTTYPE))
        u_a1reg (.CLK(CLK), .RST(RSTA), .CE(CEA), .D(a0_reg_out), .Q(a1_reg_out));

    pipe_reg #(.WIDTH(18), .REG_EN(B0REG), .RSTTYPE(RSTTYPE))
        u_b0reg (.CLK(CLK), .RST(RSTB), .CE(CEB), .D(b_src), .Q(b0_reg_out));

    pipe_reg #(.WIDTH(48), .REG_EN(CREG), .RSTTYPE(RSTTYPE))
        u_creg (.CLK(CLK), .RST(RSTC), .CE(CEC), .D(C), .Q(c_reg_out));

    pipe_reg #(.WIDTH(8), .REG_EN(OPMODEREG), .RSTTYPE(RSTTYPE))
        u_opmodereg (.CLK(CLK), .RST(RSTOPMODE), .CE(CEOPMODE), .D(OPMODE), .Q(opmode_use));

    // Pre-adder/subtracter + bypass mux (opmode[4])
    preadder_sub u_preadder (
        .D(d_reg_out), .B(b0_reg_out), .sub(opmode_use[6]), .result(preadd_result)
    );

    assign b1_in = opmode_use[4] ? preadd_result : b0_reg_out;

    pipe_reg #(.WIDTH(18), .REG_EN(B1REG), .RSTTYPE(RSTTYPE))
        u_b1reg (.CLK(CLK), .RST(RSTB), .CE(CEB), .D(b1_in), .Q(b1_reg_out));

    assign BCOUT = b1_reg_out;

    // Multiplier
    assign mult_result = $signed(a1_reg_out) * $signed(b1_reg_out);

    pipe_reg #(.WIDTH(36), .REG_EN(MREG), .RSTTYPE(RSTTYPE))
        u_mreg (.CLK(CLK), .RST(RSTM), .CE(CEM), .D(mult_result), .Q(m_out));

    assign M = m_out;

    // Carry-in select + register
    assign cyi_in = (CARRYINSEL == "CARRYIN") ? CARRYIN :
                     (CARRYINSEL == "OPMODE5") ? opmode_use[5] : 1'b0;

    pipe_reg #(.WIDTH(1), .REG_EN(CARRYINREG), .RSTTYPE(RSTTYPE))
        u_cyireg (.CLK(CLK), .RST(RSTCARRYIN), .CE(CECARRYIN), .D(cyi_in), .Q(cin_final));

    // X mux (opmode[1:0]) and Z mux (opmode[3:2])
    mux4 #(.WIDTH(48)) u_xmux (
        .sel(opmode_use[1:0]),
        .in0(48'b0),
        .in1({{12{m_out[35]}}, m_out}),
        .in2(p_reg_out),
        .in3({d_reg_out[11:0], a1_reg_out, b1_reg_out}),
        .out(x_val)
    );

    mux4 #(.WIDTH(48)) u_zmux (
        .sel(opmode_use[3:2]),
        .in0(48'b0),
        .in1(PCIN),
        .in2(p_reg_out),
        .in3(c_reg_out),
        .out(z_val)
    );

    // Post-adder/subtracter
    postadder_sub u_postadder (
        .Z(z_val), .X(x_val), .CIN(cin_final), .sub(opmode_use[7]),
        .result(post_result), .carry(post_carry)
    );

    pipe_reg #(.WIDTH(48), .REG_EN(PREG), .RSTTYPE(RSTTYPE))
        u_preg (.CLK(CLK), .RST(RSTP), .CE(CEP), .D(post_result), .Q(p_reg_out));

    assign P     = p_reg_out;
    assign PCOUT = p_reg_out;

    // Carry-out register
    pipe_reg #(.WIDTH(1), .REG_EN(CARRYOUTREG), .RSTTYPE(RSTTYPE))
        u_cyoreg (.CLK(CLK), .RST(RSTCARRYIN), .CE(CECARRYIN), .D(post_carry), .Q(CARRYOUT));

    assign CARRYOUTF = CARRYOUT;

endmodule
