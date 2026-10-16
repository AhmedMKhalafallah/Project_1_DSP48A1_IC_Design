// DSP48A1 Testbench - Directed / self-checking
`timescale 1ns/1ps

module DSP48A1_tb;

    // Clock
    reg CLK;

    // Data inputs
    reg [17:0] A, B, D;
    reg [47:0] C;
    reg        CARRYIN;
    reg [7:0]  OPMODE;
    reg [17:0] BCIN;
    reg [47:0] PCIN;

    // Reset inputs
    reg RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE;

    // Clock-enable inputs
    reg CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE;

    // Outputs
    wire [17:0] BCOUT;
    wire [47:0] PCOUT;
    wire [47:0] P;
    wire [35:0] M;
    wire        CARRYOUT;
    wire        CARRYOUTF;

    integer pass_count = 0;
    integer fail_count = 0;

  
    // DUT instantiation - default parameters match the spec:
    // A0REG=0 A1REG=1 B0REG=0 B1REG=1 CREG=1 DREG=1 MREG=1 PREG=1
    // CARRYINREG=1 CARRYOUTREG=1 OPMODEREG=1
    // CARRYINSEL="OPMODE5" B_INPUT="DIRECT" RSTTYPE="SYNC"
    DSP48A1 dut (
        .A(A), .B(B), .D(D), .C(C),
        .CLK(CLK), .CARRYIN(CARRYIN),
        .OPMODE(OPMODE), .BCIN(BCIN), .PCIN(PCIN),
        .RSTA(RSTA), .RSTB(RSTB), .RSTM(RSTM), .RSTP(RSTP),
        .RSTC(RSTC), .RSTD(RSTD), .RSTCARRYIN(RSTCARRYIN), .RSTOPMODE(RSTOPMODE),
        .CEA(CEA), .CEB(CEB), .CEM(CEM), .CEP(CEP),
        .CEC(CEC), .CED(CED), .CECARRYIN(CECARRYIN), .CEOPMODE(CEOPMODE),
        .BCOUT(BCOUT), .PCOUT(PCOUT), .P(P), .M(M),
        .CARRYOUT(CARRYOUT), .CARRYOUTF(CARRYOUTF)
    );

    // Clock: 10 ns period
    initial CLK = 1'b0;
    always #5 CLK = ~CLK;

    // Self-check helper task
    task check48(input [47:0] actual, input [47:0] expected, input [255:0] name);
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %s : expected=%h actual=%h", name, expected, actual);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %s : expected=%h actual=%h", name, expected, actual);
            end
        end
    endtask

    task check1(input actual, input expected, input [255:0] name);
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %s : expected=%b actual=%b", name, expected, actual);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %s : expected=%b actual=%b", name, expected, actual);
            end
        end
    endtask

    // Stimulus
    initial begin
        // 2.1 Verify Reset Operation
        RSTA=1; RSTB=1; RSTM=1; RSTP=1; RSTC=1; RSTD=1; RSTCARRYIN=1; RSTOPMODE=1;
        CEA=0; CEB=0; CEM=0; CEP=0; CEC=0; CED=0; CECARRYIN=0; CEOPMODE=0;

        A = $random; B = $random; D = $random; C = {$random,$random};
        CARRYIN = $random; OPMODE = $random; BCIN = $random; PCIN = {$random,$random};

        @(negedge CLK);
        #1;
        $display("\n---- Reset Check ----");
        check48(P,     48'h0, "Reset: P");
        check48(PCOUT, 48'h0, "Reset: PCOUT");
        check48({30'b0,BCOUT}, 48'h0, "Reset: BCOUT");
        check48({12'b0,M},     48'h0, "Reset: M");
        check1(CARRYOUT,  1'b0, "Reset: CARRYOUT");
        check1(CARRYOUTF, 1'b0, "Reset: CARRYOUTF");

        RSTA=0; RSTB=0; RSTM=0; RSTP=0; RSTC=0; RSTD=0; RSTCARRYIN=0; RSTOPMODE=0;
        CEA=1; CEB=1; CEM=1; CEP=1; CEC=1; CED=1; CECARRYIN=1; CEOPMODE=1;

        // 2.2 Verify DSP Path 1 : pre-sub -> mult -> post-sub
        // OPMODE = 8'b11011101
        @(negedge CLK);
        OPMODE = 8'b11011101;
        A = 20; B = 10; C = 350; D = 25;
        BCIN = $random; PCIN = {$random,$random}; CARRYIN = $random;

        repeat (4) @(negedge CLK);
        #1;
        $display("\n---- Path 1 Check ----");
        check48({30'b0,BCOUT}, 48'h0000000000f, "Path1: BCOUT");
        check48({12'b0,M},     48'h00000000012c, "Path1: M");
        check48(P,     48'h32, "Path1: P");
        check48(PCOUT, 48'h32, "Path1: PCOUT");
        check1(CARRYOUT,  1'b0, "Path1: CARRYOUT");
        check1(CARRYOUTF, 1'b0, "Path1: CARRYOUTF");

        // 2.3 Verify DSP Path 2 : pre-add -> mult -> post-add(zeros)
        // OPMODE = 8'b00010000
        @(negedge CLK);
        OPMODE = 8'b00010000;
        A = 20; B = 10; C = 350; D = 25;
        BCIN = $random; PCIN = {$random,$random}; CARRYIN = $random;

        repeat (3) @(negedge CLK);
        #1;
        $display("\n---- Path 2 Check ----");
        check48({30'b0,BCOUT}, 48'h023, "Path2: BCOUT");
        check48({12'b0,M},     48'h2bc, "Path2: M");
        check48(P,     48'h0, "Path2: P");
        check48(PCOUT, 48'h0, "Path2: PCOUT");
        check1(CARRYOUT,  1'b0, "Path2: CARRYOUT");
        check1(CARRYOUTF, 1'b0, "Path2: CARRYOUTF");

        // 2.4 Verify DSP Path 3 : no pre-adder, P feedback (accumulator)
        // OPMODE = 8'b00001010
        @(negedge CLK);
        OPMODE = 8'b00001010;
        A = 20; B = 10; C = 350; D = 25;
        BCIN = $random; PCIN = {$random,$random}; CARRYIN = $random;

        repeat (3) @(negedge CLK);
        #1;
        $display("\n---- Path 3 Check ----");
        check48({30'b0,BCOUT}, 48'h00a, "Path3: BCOUT");
        check48({12'b0,M},     48'h0c8, "Path3: M");
        // P/PCOUT and CARRYOUT/CARRYOUTF should equal each other
        // (P is fed back through X and Z muxes)
        check48(P, PCOUT, "Path3: P == PCOUT (feedback consistency)");
        check1(CARRYOUT, CARRYOUTF, "Path3: CARRYOUT == CARRYOUTF (feedback consistency)");

        // 2.5 Verify DSP Path 4 : D:A:B concat -> X , PCIN -> Z , subtract
        // OPMODE = 8'b10100111
        @(negedge CLK);
        OPMODE = 8'b10100111;
        A = 5; B = 6; C = 350; D = 25; PCIN = 3000;
        BCIN = $random; CARRYIN = $random;

        repeat (3) @(negedge CLK);
        #1;
        $display("\n---- Path 4 Check ----");
        check48({30'b0,BCOUT}, 48'h006, "Path4: BCOUT");
        check48({12'b0,M},     48'h01e, "Path4: M");
        check48(P,     48'hfe6fffec0bb1, "Path4: P");
        check48(PCOUT, 48'hfe6fffec0bb1, "Path4: PCOUT");
        check1(CARRYOUT,  1'b1, "Path4: CARRYOUT");
        check1(CARRYOUTF, 1'b1, "Path4: CARRYOUTF");

        // Summary
        #20;
        $display("TEST SUMMARY : %0d PASSED , %0d FAILED", pass_count, fail_count);

        $stop;
    end

endmodule
