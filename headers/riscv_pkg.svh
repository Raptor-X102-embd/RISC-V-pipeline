`ifndef RISCV_PKG
`define RISCV_PKG

`timescale 1ns/1ps
package riscv_pkg;

    typedef enum logic [6:0] {
        OPC_LUI     = 7'b0110111,
        OPC_AUIPC   = 7'b0010111,
        OPC_JAL     = 7'b1101111,
        OPC_JALR    = 7'b1100111,
        OPC_BRANCH  = 7'b1100011,
        OPC_LOAD    = 7'b0000011,
        OPC_STORE   = 7'b0100011,
        OPC_OP_IMM  = 7'b0010011,
        OPC_OP      = 7'b0110011,
        OPC_SYSTEM  = 7'b1110011
    } opcode_e;

    typedef enum logic [2:0] {
        FMT_R, FMT_I, FMT_S, FMT_B, FMT_U, FMT_J
    } fmt_t;

    typedef enum logic [4:0] {
        ALU_NONE, ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR,
        ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU
    } alu_op_t;

    typedef enum logic [2:0] {
        LOAD_LB, LOAD_LH, LOAD_LW, LOAD_LBU, LOAD_LHU, 
        STORE_SB, STORE_SH, STORE_SW
    } memory_size_t;

    typedef enum logic [2:0] {
        BRANCH_BEQ, BRANCH_BNE, BRANCH_NONE,
        BRANCH_BLT = 3'b100, BRANCH_BGE, BRANCH_BLTU, BRANCH_BGEU
    } branch_cond_t;

    typedef enum logic [3:0] {
        SYS_ECALL, SYS_EBREAK, SYS_CSRRW, SYS_CSRRS,
        SYS_CSRRC, SYS_CSRRWI, SYS_CSRRSI, SYS_CSRRCI,
        SYS_NONE = 4'b1111
    } sys_op_t;

    typedef enum logic [7:0] {
        NO_ERROR = 0,
        ADDR_ERROR = 1,
        UNKNOWN_MEM_SIZE = 2
    } mem_resp_err_t;

    typedef struct packed {
        fmt_t         format;
        logic [6:0]   opcode;
        logic [4:0]   rd;
        logic [4:0]   rs1;
        logic [4:0]   rs2;
        logic [2:0]   funct3;
        logic [6:0]   funct7;
        logic [31:0]  imm;

        logic         is_alu;
        logic         is_load;
        logic         is_store;
        logic         is_branch;
        logic         is_jump;
        logic         is_system;

        alu_op_t      alu_op;
        memory_size_t mem_sz_type;
        branch_cond_t branch_cond;
        sys_op_t      sys_op;

        logic         reg_write;
        logic         jump_reg;
        logic         mem_read;
        logic         mem_write;
        logic         use_imm;
        logic         use_pc;

        logic         valid;
    } decoded_instr_t;

endpackage
`endif
