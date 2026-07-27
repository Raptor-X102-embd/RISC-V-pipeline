`timescale 1ns/1ps

module tb_top;

    reg clk = 0;
    reg reset = 1;

    top_module #(
        .INIT_DATA_FILE("data/instr_file.mem"),
        .INSTR_WIDTH(32)
    ) u_top (
        .clk (clk),
        .reset(reset)
    );

    always #10 clk = ~clk;

    initial begin
        reset = 1;
        #20;
        reset = 0;
        #20;

        $display("Loading program...");
    //  32'h00700313; #20; // addi x6, x0, 7
    //  32'h006283b3; #20; // add  x7, x5, x6
    //  32'h00702023; #20; // sw   x7, 0(x0)
    //  32'h00002403; #20; // lw   x8, 0(x0)
    //  32'h00000013; #20; // nop
      
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
