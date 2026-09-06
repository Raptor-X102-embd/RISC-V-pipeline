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

    // Параметры памяти (должны совпадать с параметрами top_module)
    localparam MEM_SIZE   = 1024;          // в байтах
    localparam DATA_WIDTH = 32;            // ширина слова
    localparam DATA_WIDTH_BYTES = DATA_WIDTH / 8;
    localparam WORDS = MEM_SIZE / DATA_WIDTH_BYTES;
    localparam MIN_ADDR = 32'h00000000;

    reg clk;
    reg rst_n;

    top_module #(
        .INIT_DATA_FILE(INIT_DATA_FILE)
    ) u_top (
        .clk (clk),
        .rst_n(rst_n)
    );

    always #10 clk = ~clk;

    initial begin
        rst_n = 0;
        clk = 0;
        #20;
        rst_n = 1;
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
            logic [DATA_WIDTH-1:0] mem_word;
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
                        // Проверка адреса в пределах памяти
                        if (addr >= MIN_ADDR && addr < MIN_ADDR + MEM_SIZE) begin
                            // Чтение слова из AXI-слейва
                            // Путь: top_module.u_memory.u_mem.u_slave.mem
                            // Массив индексируется от MIN_ADDR до MIN_ADDR+WORDS-1
                            // Байтовый адрес преобразуем в индекс слова и смещение
                            automatic logic [31:0] word_addr = addr >> $clog2(DATA_WIDTH_BYTES);
                            automatic logic [31:0] byte_offset = addr & (DATA_WIDTH_BYTES-1);
                            // Проверка, что индекс в пределах массива
                            if (word_addr >= MIN_ADDR && word_addr < MIN_ADDR + WORDS) begin
                                mem_word = u_top.u_memory.u_mem.u_slave.mem[word_addr];
                                mem_byte = mem_word[byte_offset*8 +: 8];
                                if (mem_byte !== mem_value) begin
                                    $display("FAIL: mem[%0d] = 0x%0h, expected 0x%0h", addr, mem_byte, mem_value);
                                    $display("word_addr: %0d, byte_offset = %0d", word_addr, byte_offset);
                                    $finish;
                                end else begin
                                    $display("PASS: mem[%0d] = 0x%0h", addr, mem_value);
                                end
                            end else begin
                                $display("ERROR: word address %0d out of range", word_addr);
                                $finish;
                            end
                        end else begin
                            $display("ERROR: memory address %0d out of range [0..%0d]", addr, MIN_ADDR+MEM_SIZE-1);
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
