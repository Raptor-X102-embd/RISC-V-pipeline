`timescale 1ns/1ps

module tb_top;

    reg clk = 0;
    reg reset = 1;
    reg w_ena = 0;
    reg [31:0] w_addr = 0;
    reg [31:0] w_data = 0;
    reg r_ena = 0;

    top_module #(.INSTR_WIDTH(32)) u_top (
        .clk (clk),
        .reset(reset),
        .w_ena(w_ena),
        .w_addr(w_addr),
        .w_data(w_data),
        .r_ena(r_ena)
    );

    always #10 clk = ~clk;

    initial begin
        reset = 1;
        #20;
        reset = 0;
        #20;

        $display("Loading program...");
        w_ena = 1;
        w_addr = 32'h00000000; w_data = 32'h00500293; #20; // addi x5, x0, 5
        r_ena = 1;
        w_addr = 32'h00000004; w_data = 32'h00700313; #20; // addi x6, x0, 7
        w_addr = 32'h00000008; w_data = 32'h006283b3; #20; // add  x7, x5, x6
        w_addr = 32'h0000000c; w_data = 32'h00702023; #20; // sw   x7, 0(x0)
        w_addr = 32'h00000010; w_data = 32'h00002403; #20; // lw   x8, 0(x0)
        w_addr = 32'h00000014; w_data = 32'h00000013; #20; // nop
        w_ena = 0;
        $display("Program loaded.");

        $display("Starting pipeline...");

        repeat (1000) @(posedge clk);

        $display("x5 = %0d", u_top.u_reg_file.regs[5]);   // should be 5
        $display("x6 = %0d", u_top.u_reg_file.regs[6]);   // should be 7
        $display("x7 = %0d", u_top.u_reg_file.regs[7]);   // should be 12
        $display("x8 = %0d", u_top.u_reg_file.regs[8]);   // should be 12

        if (u_top.u_reg_file.regs[8] == 12)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: x8 = %0d, expected 12", u_top.u_reg_file.regs[8]);

        $display("Simulation finished.");
        $finish;
    end

    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_top);
        $display("VCD dumping started.");
    end

    initial begin
        #100000;
        $display("Timeout! Simulation forced to stop.");
        $finish;
    end

endmodule
