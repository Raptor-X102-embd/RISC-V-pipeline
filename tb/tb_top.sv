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

    reg clk;
    reg reset;

    top_module #(
        .INIT_DATA_FILE(INIT_DATA_FILE)
    ) u_top (
        .clk (clk),
        .reset(reset)
    );

    always #10 clk = ~clk;

    initial begin
        reset = 1;
        clk = 0;
        #20;
        reset = 0;
        #20;
        $display("Loading program...");
        $display("Program loaded.");
        $display("Starting pipeline...");

        repeat (1000) @(posedge clk);

        $display("Simulation finished, checking results...");

        if (EXPECT_FILE != "") begin
            integer fd, status;
            int addr, reg_value, mem_value;
            logic [7:0] mem_byte;
            string cmd;
            fd = $fopen(EXPECT_FILE, "r");
            if (fd == 0) begin
                $display("ERROR: Cannot open expect file %s", EXPECT_FILE);
                $finish;
            end
            while (!$feof(fd)) begin
                status = $fscanf(fd, "%s ", cmd);
                if (status == 1) begin
                    if (cmd == "reg") begin
                        status = $fscanf(fd, "%d %d\n", addr, reg_value);
                        if (status != 2) begin
                            $display("ERROR: invalid reg line in expect file");
                            $finish;
                        end
                        if (u_top.u_reg_file.regs[addr] !== reg_value) begin
                            $display("FAIL: reg[%0d] = %0d, expected %0d", addr, u_top.u_reg_file.regs[addr], reg_value);
                            $finish;
                        end else begin
                            $display("PASS: reg[%0d] = %0d", addr, reg_value);
                        end
                    end else if (cmd == "mem") begin
                        status = $fscanf(fd, "%d %d\n", addr, mem_value);
                        if (status != 2) begin
                            $display("ERROR: invalid mem line in expect file");
                            $finish;
                        end
                        if (mem_value < 0 || mem_value > 255) begin
                            $display("ERROR: mem value %d out of range (0-255)", mem_value);
                            $finish;
                        end
                        if (addr >= 0 && addr <= 248) begin // MAX_ADDR = 248 (0xF8)
                            mem_byte = u_top.u_memory.u_mem.mem[addr];
                            if (mem_byte !== mem_value) begin
                                $display("FAIL: mem[%0d] = 0x%0h, expected 0x%0h", addr, mem_byte, mem_value);
                                $finish;
                            end else begin
                                $display("PASS: mem[%0d] = 0x%0h", addr, mem_value);
                            end
                        end else begin
                            $display("ERROR: memory address %0d out of range", addr);
                            $finish;
                        end
                    end else begin
                        $display("WARNING: unknown command '%s'", cmd);
                        $fscanf(fd, "\n");
                    end
                end else begin
                    $fscanf(fd, "\n");
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
