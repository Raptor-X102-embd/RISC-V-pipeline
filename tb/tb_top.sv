`timescale 1ns/1ps

module tb_top;

    `ifdef INIT_DATA_FILE
        localparam string INIT_DATA_FILE = `INIT_DATA_FILE;
    `else
        localparam string INIT_DATA_FILE = "data/instr_file.mem";
    `endif

    `ifdef EXPECT_FILE
        localparam string EXPECT_FILE = `EXPECT_FILE;
    `else
        localparam string EXPECT_FILE = "";
    `endif

    reg clk = 0;
    reg reset = 1;

    top_module #(
        .INIT_DATA_FILE(INIT_DATA_FILE),
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
        $display("Program loaded.");
        $display("Starting pipeline...");

        repeat (1000) @(posedge clk);

        $display("Simulation finished, checking results...");

        if (EXPECT_FILE != "") begin
            integer fd;
            int addr, value, status;
            string cmd;
            fd = $fopen(EXPECT_FILE, "r");
            if (fd == 0) begin
                $display("ERROR: Cannot open expect file %s", EXPECT_FILE);
                $finish;
            end
            while (!$feof(fd)) begin
                status = $fscanf(fd, "%s %d %d\n", cmd, addr, value);
                if (status == 3) begin
                    if (cmd == "reg") begin
                        if (u_top.u_reg_file.regs[addr] !== value) begin
                            $display("FAIL: reg[%0d] = %0d, expected %0d", addr, u_top.u_reg_file.regs[addr], value);
                            $finish;
                        end else begin
                            $display("PASS: reg[%0d] = %0d", addr, value);
                        end
                    end else if (cmd == "mem") begin
                        // Access data memory. Change 'u_mem' if your instance name differs.
                        logic [31:0] mem_word;
                        mem_word = u_top.u_memory.u_mem.mem[addr];
                        if (mem_word !== value) begin
                            $display("FAIL: mem[%0d] = 0x%0h, expected 0x%0h", addr, mem_word, value);
                            $finish;
                        end else begin
                            $display("PASS: mem[%0d] = 0x%0h", addr, value);
                        end
                    end else begin
                        $display("WARNING: unknown command '%s'", cmd);
                    end
                end
            end
            $fclose(fd);
            $display("ALL TESTS PASSED");
        end else begin
            $display("No expect file, skipping checks.");
        end

        $display("Final register values (non-zero):");
        for (int i=0; i<32; i++) begin
            if (u_top.u_reg_file.regs[i] !== 0)
                $display("x%0d = %0d", i, u_top.u_reg_file.regs[i]);
        end

        $finish;
    end

    initial begin
        `ifdef VCD_FILE
            $dumpfile(`VCD_FILE);
        `else
            $dumpfile("sim.vcd");
        `endif
        $dumpvars(0, tb_top);
        $display("VCD dumping started.");
    end

    initial begin
        #100000;
        $display("Timeout! Simulation forced to stop.");
        $finish;
    end
endmodule
