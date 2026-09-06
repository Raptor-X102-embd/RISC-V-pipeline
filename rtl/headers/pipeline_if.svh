`ifndef PIPELINE_IF
`define PIPELINE_IF

`include "riscv_pkg.svh"

interface pipeline_if (input logic clk, rst_n);
    logic flush;
    logic stall;
    //logic cancel;

    // NOTE: Naming
    // signals with suffix format *_stage1_stage2 are sequential
    // signals with suffix format *_stage1 are combinational

    logic [31:0] pc;
    logic [31:0] pc_if;
    logic [31:0] pc_target;

    //branch predictor
    logic        pred_taken;
    logic [31:0] pred_target;

    // Fetch -> Decode
    logic [31:0] instr_if_id;
    logic        valid_if_id;
    logic        pred_taken_if_id;
    logic [31:0] pred_target_if_id;
    logic [31:0] pc_if_id;

    // Decode -> Execute

    // TODO: get rid of unuzed fields in execute 
    /* verilator lint_off UNUSEDSIGNAL */
    decoded_instr_t dec_id_ex;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [31:0]    pc_id_ex;
    logic [31:0]    rs1_data_id_ex;
    logic [31:0]    rs2_data_id_ex;
    logic           valid_id_ex;
    logic           pred_taken_id_ex;
    logic [31:0]    pred_target_id_ex;

    // Execute -> Memory
    logic [4:0]  rd_ex_mem;
    logic        reg_write_ex_mem;
    logic        is_load_ex;
    logic        is_load_ex_mem;
    logic        is_store_ex_mem;
    logic [31:0] alu_result_ex;     // comb logic
    logic [31:0] alu_result_ex_mem; // seq logic
    logic [31:0] rs2_data_ex_mem;
    logic        valid_ex_mem;
    logic        rs1_forward_ex;
    logic        rs2_forward_ex;
    logic        update_valid;
    logic        branch_taken;
    
    // Memory -> WriteBack
    logic [4:0]  rd_mem_wb;
    logic        reg_write_mem_wb;
    logic        is_load_mem_wb;
    logic [31:0] alu_result_mem_wb;
    logic [31:0] mem_read_data_mem;    // comb logic
    logic [31:0] mem_read_data_mem_wb; // seq logic
    logic        valid_mem_wb;
    logic        rs1_forward_mem;
    logic        rs2_forward_mem;

    // WriteBack
    logic        rs1_forward_wb;
    logic        rs2_forward_wb;

    


    // Register file
    // Read (Execute)
    logic [4:0] rs1_addr_id;
    logic [4:0] rs2_addr_id;
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
    logic       use_rs1_id;
    logic       use_rs2_id;
    logic       reg_write_ex;
    logic       valid_ex;

    modport fetch (
        input  clk, rst_n,
        input  stall, mem_stall, flush,
               pc_target, pred_taken, pred_target, branch_taken,
        output instr_if_id, pc, pc_if_id, pc_if, valid_if_id,
               pred_taken_if_id, pred_target_if_id
    );
    modport decode (
        input  clk, rst_n,
        input  stall, mem_stall, flush, instr_if_id, pc_if_id, valid_if_id,
        input  rs1_forward_ex, rs2_forward_ex, 
        input  rs1_forward_mem, rs2_forward_mem, 
        input  rs1_forward_wb, rs2_forward_wb, 
        input  is_load_ex_mem, alu_result_ex_mem, alu_result_ex, mem_read_data_mem,
        input  pred_taken_if_id, pred_target_if_id,
        input  rd_data_wb,
        output dec_id_ex, pc_id_ex, valid_id_ex,
        output rs1_addr_id, rs2_addr_id, use_rs1_id, use_rs2_id,
               rs1_data_id_ex, rs2_data_id_ex,
        output pred_taken_id_ex, pred_target_id_ex,
        input  rs1_data, rs2_data
    );
    modport execute (
        input  clk, rst_n,
        input  stall, mem_stall, dec_id_ex, pc_id_ex, rs1_data_id_ex, rs2_data_id_ex,
               valid_id_ex, rs1_addr_id, rs2_addr_id,
        // for hazard unit (comb logic)
        output rd_ex, reg_write_ex, valid_ex, use_rs1_id, use_rs2_id, 
        // sequential logic for memory
        output rd_ex_mem, reg_write_ex_mem, is_load_ex_mem, is_store_ex_mem,
               rs1_forward_ex, rs2_forward_ex, alu_result_ex_mem, alu_result_ex,
               rs2_data_ex_mem, valid_ex_mem, mem_req_type, is_load_ex,
               flush, pc_target, update_valid, branch_taken
    );
    modport memory (
        input  clk, rst_n,
        input  stall, flush, rd_ex_mem, reg_write_ex_mem, is_load_ex_mem,
               is_store_ex_mem, alu_result_ex_mem, rs2_data_ex_mem, valid_ex_mem,
               mem_req_type, rs1_addr_id, rs2_addr_id, use_rs1_id, use_rs2_id,
        output rd_mem_wb, reg_write_mem_wb, is_load_mem_wb,
               alu_result_mem_wb, mem_read_data_mem, mem_read_data_mem_wb, valid_mem_wb,
               mem_stall, mem_resp_error, rs1_forward_mem, rs2_forward_mem
    );
    modport writeback (
        input  rd_mem_wb, reg_write_mem_wb, is_load_mem_wb,
               alu_result_mem_wb, mem_read_data_mem_wb, valid_mem_wb,
               rs1_addr_id, rs2_addr_id, use_rs1_id, use_rs2_id,
        output rd_addr_wb, rd_data_wb, rd_w_ena_wb, rs1_forward_wb, rs2_forward_wb
    );


    modport regfile (
        input clk, rst_n,
        input  rs1_addr_id, rs2_addr_id, rd_addr_wb, rd_data_wb, rd_w_ena_wb,
        output rs1_data, rs2_data
    );

    modport memory_map (
        input  clk, rst_n,// cancel,
        input  valid_ex_mem, alu_result_ex_mem, rs2_data_ex_mem, mem_req_type,
        output mem_read_data_mem_wb, mem_resp_error 
    );

    modport hazard_unit (
        // Decode
        input  rs1_addr_id, rs2_addr_id, valid_if_id, use_rs1_id, use_rs2_id,
        // Execute
        input  rd_ex, reg_write_ex, valid_ex, is_load_ex,
        // Memory
        input  rd_ex_mem, reg_write_ex_mem, valid_ex_mem,
        input  mem_stall,
        // Writeback
        input  rd_mem_wb, reg_write_mem_wb, valid_mem_wb,
        output stall
    );

    modport branch_predictor (
        input    clk,
        input    rst_n,
        // Fetch
        input    pc,
        output   pred_taken,
        output   pred_target,
        output   flush,
        // Execute
        input    update_valid,
        // TODO: get rid of it (is equal to valid_id_ex)
        input    valid_id_ex,
        input    pc_id_ex,
        input    branch_taken,
        input    pc_target,
        input    pred_taken_id_ex,
        input    pred_target_id_ex
    );

endinterface
`endif
