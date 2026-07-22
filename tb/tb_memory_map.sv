`timescale 1ns/1ps

module tb_memory_map;

    parameter DATA_WIDTH = 8;
    parameter MAX_DATA_W = 32;
    parameter MAX_DATA_R = 32;

    logic clk;
    logic areset;
    logic r_ena;
    logic [31:0] r_addr;
    logic [MAX_DATA_R-1:0] r_data;
    logic w_ena;
    logic [31:0] w_addr;
    logic [MAX_DATA_W-1:0] w_data;
    memory_size_t mem_sz_type;
    mem_resp_err_t mem_resp_error;

    memory_map #(
        .DATA_WIDTH (DATA_WIDTH),
        .MAX_DATA_W (MAX_DATA_W),
        .MAX_DATA_R (MAX_DATA_R),
        .MIN_ADDR   (32'h00000000),
        .MAX_ADDR   (32'h000000F8)
    ) u_mem_map (
        .clk   (clk),
        .areset(areset),
        .r_ena (r_ena),
        .r_addr(r_addr),
        .r_data(r_data),
        .w_ena (w_ena),
        .w_addr(w_addr),
        .w_data(w_data),
        .mem_sz_type (mem_sz_type),
        .mem_resp_error (mem_resp_error)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        areset = 1;      
        r_ena = 0;
        w_ena = 0;
        w_addr = 32'h0;
        w_data = 32'h0;
        mem_sz_type = STORE_SW;
        r_addr = 32'h0;

        repeat (5) @(posedge clk);
        areset = 0;
        @(posedge clk); 

        $display("=== Test 1: Write SW to addr 0 ===");
        @(posedge clk);
        w_ena = 1;
        w_addr = 32'h00000000;
        w_data = 32'h0000000C;
        mem_sz_type = STORE_SW;
        @(posedge clk);
        w_ena = 0;

        repeat (2) @(posedge clk);

        $display("=== Test 2: Read LW from addr 0 ===");
        @(posedge clk);
        r_ena = 1;
        r_addr = 32'h00000000;
        mem_sz_type = LOAD_LW;
        @(posedge clk);
        r_ena = 0;
        #10; 

        $display("r_data = 0x%08h", r_data);
        $display("mem_resp_error = %d", mem_resp_error);
        if (r_data == 32'h0000000C)
            $display("Test PASSED: Write and read correct");
        else
            $display("Test FAILED: r_data = 0x%08h, expected 0x0000000C", r_data);

        $display("=== Test 3: Write SB to addr 4 ===");
        @(posedge clk);
        w_ena = 1;
        w_addr = 32'h00000004;
        w_data = 32'h000000AA;
        mem_sz_type = STORE_SB;
        @(posedge clk);
        w_ena = 0;
        repeat (2) @(posedge clk);

        @(posedge clk);
        r_ena = 1;
        r_addr = 32'h00000004;
        mem_sz_type = LOAD_LW;
        @(posedge clk);
        r_ena = 0;
        #10;
        $display("r_data (addr4) = 0x%08h", r_data);
        if (r_data == 32'h000000AA)
            $display("SB Test PASSED");
        else
            $display("SB Test FAILED: got 0x%08h, expected 0x000000AA", r_data);

        $display("=== Test 4: Write SH to addr 8 ===");
        @(posedge clk);
        w_ena = 1;
        w_addr = 32'h00000008;
        w_data = 32'h0000BBCC;
        mem_sz_type = STORE_SH;
        @(posedge clk);
        w_ena = 0;
        repeat (2) @(posedge clk);

        @(posedge clk);
        r_ena = 1;
        r_addr = 32'h00000008;
        mem_sz_type = LOAD_LW;
        @(posedge clk);
        r_ena = 0;
        #10;
        $display("r_data (addr8) = 0x%08h", r_data);
        if (r_data == 32'h0000BBCC)
            $display("SH Test PASSED");
        else
            $display("SH Test FAILED: got 0x%08h, expected 0x0000BBCC", r_data);

        @(posedge clk);
        r_ena = 1;
        r_addr = 32'h00000000;
        mem_sz_type = LOAD_LW;
        @(posedge clk);
        r_ena = 0;
        #10;
        $display("r_data (addr0 after other writes) = 0x%08h", r_data);
        if (r_data == 32'h0000000C)
            $display("Data at addr0 still correct");
        else
            $display("Data at addr0 corrupted: got 0x%08h, expected 0x0000000C", r_data);

        $display("Simulation finished.");
        $finish;
    end

    initial begin
        $dumpfile("tb_memory_map.vcd");
        $dumpvars(0, tb_memory_map);
    end

endmodule
