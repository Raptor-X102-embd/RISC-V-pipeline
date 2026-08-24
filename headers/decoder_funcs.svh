`ifndef DECODER_FUNCS_SVH
`define DECODER_FUNCS_SVH

/* verilator lint_off IMPORTSTAR */
import riscv_pkg::*;
/* verilator lint_on IMPORTSTAR */
function automatic void decode_fmt_r(ref decoded_instr_t dec, input logic [31:0] instr);
    //dec.imm       = 32'b0;
    dec.use_rs1   = 1'b1;
    dec.use_rs2   = 1'b1;
    dec.reg_write = 1'b1;
    dec.is_alu    = 1'b1;
    dec.valid     = 1'b1;

    unique case ({dec.funct3, dec.funct7})
        {3'b000, 7'b0000000}: dec.alu_op = ALU_ADD;
        {3'b000, 7'b0100000}: dec.alu_op = ALU_SUB;
        {3'b001, 7'b0000000}: dec.alu_op = ALU_SLL;
        {3'b101, 7'b0000000}: dec.alu_op = ALU_SRL;
        {3'b101, 7'b0100000}: dec.alu_op = ALU_SRA;
        {3'b010, 7'b0000000}: dec.alu_op = ALU_SLT;
        {3'b011, 7'b0000000}: dec.alu_op = ALU_SLTU;
        {3'b100, 7'b0000000}: dec.alu_op = ALU_XOR;
        {3'b110, 7'b0000000}: dec.alu_op = ALU_OR;
        {3'b111, 7'b0000000}: dec.alu_op = ALU_AND;
        default: dec.valid = 1'b0;
    endcase
endfunction

function automatic void decode_fmt_i(ref decoded_instr_t dec, input logic [31:0] instr);
    dec.use_imm = 1'b1;
    dec.imm       = { {20{instr[31]}}, instr[31:20] };
    dec.use_rs1   = 1'b1;
    dec.use_rs2   = 1'b0;
    dec.reg_write = 1'b1;
    dec.valid     = 1'b1;

    unique case (dec.opcode)
        OPC_OP_IMM: begin
            dec.is_alu = 1'b1;

            unique case (dec.funct3)
                3'b000: dec.alu_op = ALU_ADD;
                3'b010: dec.alu_op = ALU_SLT;
                3'b011: dec.alu_op = ALU_SLTU;
                3'b100: dec.alu_op = ALU_XOR;
                3'b110: dec.alu_op = ALU_OR;
                3'b111: dec.alu_op = ALU_AND;
                3'b001: dec.alu_op = ALU_SLL;
                3'b101: begin
                    if      (dec.funct7 == 7'b0100000) dec.alu_op = ALU_SRA;
                    else if (dec.funct7 == 7'b0)       dec.alu_op = ALU_SRL;
                    else dec.valid = 1'b0;
                end
                default: dec.valid = 1'b0;
            endcase
        end

        OPC_LOAD: begin
            dec.is_load = 1'b1;
            dec.alu_op = ALU_ADD;

            unique case (dec.funct3)
                3'b000: dec.mem_sz_type = LOAD_LB;
                3'b001: dec.mem_sz_type = LOAD_LH;
                3'b010: dec.mem_sz_type = LOAD_LW;
                3'b100: dec.mem_sz_type = LOAD_LBU;
                3'b101: dec.mem_sz_type = LOAD_LHU;
                default: dec.valid = 1'b0;
            endcase
        end

        OPC_JALR: begin
            dec.is_jump = 1'b1;
            dec.jump_reg = 1'b1;
            //dec.use_pc = 1'b1;
            dec.is_alu = 1'b1;
            //dec.alu_op = ALU_ADD;

            dec.valid = dec.funct3 == 3'b000;
        end

        OPC_SYSTEM: begin
            dec.is_system = 1'b1;
            //dec.use_imm = 1'b0; ?

            unique case (dec.funct3)
                3'b000: begin
                    dec.use_rs1 = 1'b0;
                    dec.reg_write = 1'b0;

                    if      (dec.imm[11:0] == 12'b0)            dec.sys_op = SYS_ECALL;
                    else if (dec.imm[11:0] == 12'b000000000001) dec.sys_op = SYS_EBREAK;
                    else dec.valid = 1'b0;
                end
                3'b001: dec.sys_op = SYS_CSRRW;
                3'b010: dec.sys_op = SYS_CSRRS;
                3'b011: dec.sys_op = SYS_CSRRC;
                3'b101: dec.sys_op = SYS_CSRRWI;
                3'b110: dec.sys_op = SYS_CSRRSI;
                3'b111: dec.sys_op = SYS_CSRRCI;
                default: dec.valid = 1'b0;
            endcase
        end

        default: dec.valid = 1'b0;
    endcase
endfunction

function automatic void decode_fmt_s(ref decoded_instr_t dec, input logic [31:0] instr);
    dec.imm       = { {20{instr[31]}}, instr[31:25], instr[11:7] };
    dec.use_rs1   = 1'b1;
    dec.use_rs2   = 1'b1;
    dec.is_store  = 1'b1;
    dec.use_imm   = 1'b1;
    dec.alu_op    = ALU_ADD;
    dec.valid     = 1'b1;

    unique case (dec.funct3)
        3'b000: dec.mem_sz_type = STORE_SB;
        3'b001: dec.mem_sz_type = STORE_SH;
        3'b010: dec.mem_sz_type = STORE_SW;
        default: dec.valid = 1'b0;
    endcase
endfunction

function automatic void decode_fmt_b(ref decoded_instr_t dec, input logic [31:0] instr);
    dec.imm       = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
    dec.use_rs1   = 1'b1;
    dec.use_rs2   = 1'b1;
    dec.is_branch = 1'b1;
    dec.valid     = 1'b1;

    case (dec.funct3)
        3'b000: dec.branch_cond = BRANCH_BEQ;
        3'b001: dec.branch_cond = BRANCH_BNE;
        3'b100: dec.branch_cond = BRANCH_BLT;
        3'b101: dec.branch_cond = BRANCH_BGE;
        3'b110: dec.branch_cond = BRANCH_BLTU;
        3'b111: dec.branch_cond = BRANCH_BGEU;
        default: dec.valid = 1'b0;
    endcase
endfunction

function automatic void decode_fmt_u(ref decoded_instr_t dec, input logic [31:0] instr);
    dec.imm       = { instr[31:12], 12'b0 };
    dec.use_rs1   = 1'b0;
    dec.use_rs2   = 1'b0;
    dec.reg_write = 1'b1;
    dec.is_alu    = 1'b1;
    dec.use_imm   = 1'b1;
    dec.valid     = 1'b1;

    unique case (dec.opcode)
        OPC_LUI:   dec.alu_op = ALU_ADD;
        OPC_AUIPC: dec.use_pc = 1'b1;
        default:   dec.valid = 1'b0;
    endcase
endfunction

function automatic void decode_fmt_j(ref decoded_instr_t dec, input logic [31:0] instr);
    dec.imm       = { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 };
    dec.use_rs1   = 1'b0;
    dec.use_rs2   = 1'b0;
    dec.reg_write = 1'b1;
    dec.is_jump   = 1'b1;
    dec.is_alu    = 1'b1;
    dec.use_pc    = 1'b1;
    dec.valid     = 1'b1;
endfunction

`endif
