`ifndef PIPELINE_IF
`define PIPELINE_IF

`include "riscv_pkg.svh"

interface pipeline_if (input logic clk, reset);
    logic flush;
    logic stall;
    logic cancel;

    // Fetch -> Decode
    logic [31:0] instr_if_id;
    logic [31:0] pc_if_id;
    logic        valid_if_id;

    // Decode -> Execute
    decoded_instr_t dec_id_ex;
    logic [31:0]    pc_id_ex;
    logic [31:0]    rs1_data_id_ex;
    logic [31:0]    rs2_data_id_ex;
    logic           valid_id_ex;

    // Execute -> Memory
    logic [4:0]  rd_ex_mem;
    logic        reg_write_ex_mem;
    logic        is_load_ex_mem;
    logic        is_store_ex_mem;
    logic [31:0] alu_result_ex_mem;
    logic [31:0] rs2_data_ex_mem;
    logic        valid_ex_mem;

    // Memory -> WriteBack
    logic [4:0]  rd_mem_wb;
    logic        reg_write_mem_wb;
    logic        is_load_mem_wb;
    logic [31:0] alu_result_mem_wb;
    logic [31:0] mem_read_data_mem_wb;
    logic        valid_mem_wb;

    logic [31:0] pc;
    logic [31:0] pc_target;

    // Register file
    // Read (Execute)
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    // Write (WriteBack)
    logic [4:0]  rd_addr_wb;
    logic [31:0] rd_data_wb;
    logic        rd_w_ena_wb;

    // memory_top && memory_map signals
    logic [2:0]    mem_req_type;   // LOAD/STORE + size
    logic          mem_stall;
    mem_resp_err_t mem_resp_error;

    // hazard detection 
    logic [4:0] rd_ex;
    logic       reg_write_ex;
    logic       valid_ex;

    modport fetch (
        input clk, reset,
        input  stall, mem_stall, flush, pc_target,
        output instr_if_id, pc_if_id, valid_if_id, pc
    );
    modport decode (
        input clk, reset,
        input  stall, mem_stall, flush, instr_if_id, pc_if_id, valid_if_id,
        output dec_id_ex, pc_id_ex, valid_id_ex,
        output rs1_addr, rs2_addr, rs1_data_id_ex, rs2_data_id_ex,
        input  rs1_data, rs2_data
    );
    modport execute (
        input clk, reset,
        input  stall, mem_stall, dec_id_ex, pc_id_ex, rs1_data_id_ex, rs2_data_id_ex, valid_id_ex,
        // for hazard unit (comb logic)
        output rd_ex, reg_write_ex, valid_ex,
        // sequential logic for memory
        output rd_ex_mem, reg_write_ex_mem, is_load_ex_mem, is_store_ex_mem,
               alu_result_ex_mem, rs2_data_ex_mem, valid_ex_mem, mem_req_type,
               flush, pc_target
    );
    modport memory (
        input  clk, reset,
        input  stall, flush, rd_ex_mem, reg_write_ex_mem, is_load_ex_mem,
               is_store_ex_mem, alu_result_ex_mem, rs2_data_ex_mem, valid_ex_mem,
               mem_req_type,
        output rd_mem_wb, reg_write_mem_wb, is_load_mem_wb,
               alu_result_mem_wb, mem_read_data_mem_wb, valid_mem_wb,
               mem_stall, mem_resp_error
    );
    modport writeback (
        input  rd_mem_wb, reg_write_mem_wb, is_load_mem_wb,
               alu_result_mem_wb, mem_read_data_mem_wb, valid_mem_wb,
        output rd_addr_wb, rd_data_wb, rd_w_ena_wb
    );


    modport regfile (
        input clk, reset,
        input  rs1_addr, rs2_addr, rd_addr_wb, rd_data_wb, rd_w_ena_wb,
        output rs1_data, rs2_data
    );

    modport memory_map (
        input  clk, reset, cancel,
        input  valid_ex_mem, alu_result_ex_mem, rs2_data_ex_mem, mem_req_type,
        output mem_read_data_mem_wb, mem_resp_error 
    );

    modport hazard_unit (
        // Decode
        input  rs1_addr, rs2_addr, valid_if_id,
        // Execute
        input  rd_ex, reg_write_ex, valid_ex,
        // Memory
        input  rd_ex_mem, reg_write_ex_mem, valid_ex_mem,
        input  mem_stall,
        // Writeback
        input  rd_mem_wb, reg_write_mem_wb, valid_mem_wb,

        output stall
    );

endinterface
`endif
