`include "pipeline_if.svh"

module alu_top(
    pipeline_if.execute bus,
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [31:0] pc,
    output logic [31:0] alu_result
);
    
    logic [31:0] op2;
    assign op2 = bus.dec_id_ex.use_imm ? bus.dec_id_ex.imm : rs2_data;

    always_comb begin
        if (bus.dec_id_ex.is_jump) begin
            alu_result = pc + 32'd4; // JAL, JALR
        end else if (bus.dec_id_ex.use_pc) begin
            alu_result = pc + op2; // only for AUIPC
        end else begin
            unique case (bus.dec_id_ex.alu_op)
                ALU_ADD:  alu_result = rs1_data + op2; // also LUI, LOAD, STORE 
                ALU_SUB:  alu_result = rs1_data - op2;
                ALU_AND:  alu_result = rs1_data & op2;
                ALU_OR:   alu_result = rs1_data | op2;
                ALU_XOR:  alu_result = rs1_data ^ op2;
                ALU_SLL:  alu_result = rs1_data << op2[4:0];
                ALU_SRL:  alu_result = rs1_data >> op2[4:0];
                ALU_SRA:  alu_result = rs1_data >>> op2[4:0];
                ALU_SLTU: alu_result = {31'b0, rs1_data < op2};
                ALU_SLT:  alu_result = {31'b0, $signed(rs1_data) < $signed(op2)};
                default:  alu_result = 'b0;
            endcase
        end
    end
endmodule
