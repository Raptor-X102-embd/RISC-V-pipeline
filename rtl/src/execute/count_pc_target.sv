`include "pipeline_if.svh"

module count_pc_target (
    pipeline_if.execute bus
);

    always_comb begin
        if (bus.dec_id_ex.is_jump) begin
            bus.branch_taken = 1'b1;
            if (bus.dec_id_ex.jump_reg)
                bus.pc_target = bus.rs1_data_id_ex + bus.dec_id_ex.imm; // JALR
            else 
                bus.pc_target = bus.pc_id_ex + bus.dec_id_ex.imm; // JAL
        end else if (bus.dec_id_ex.is_branch) begin
            bus.pc_target = bus.pc_id_ex + bus.dec_id_ex.imm;
            unique case (bus.dec_id_ex.branch_cond)
                BRANCH_BEQ:  bus.branch_taken = bus.rs1_data_id_ex == bus.rs2_data_id_ex;
                BRANCH_BNE:  bus.branch_taken = bus.rs1_data_id_ex != bus.rs2_data_id_ex;
                BRANCH_BLT:  bus.branch_taken = $signed(bus.rs1_data_id_ex) <  $signed(bus.rs2_data_id_ex);
                BRANCH_BGE:  bus.branch_taken = $signed(bus.rs1_data_id_ex) >= $signed(bus.rs2_data_id_ex);
                BRANCH_BLTU: bus.branch_taken = bus.rs1_data_id_ex <  bus.rs2_data_id_ex;
                BRANCH_BGEU: bus.branch_taken = bus.rs1_data_id_ex >= bus.rs2_data_id_ex;
                default: begin
                    bus.branch_taken = 1'b0;
                    bus.pc_target = bus.pc_id_ex + 32'd4;
                end
            endcase
        end else begin
            bus.branch_taken = 1'b0;
            bus.pc_target = bus.pc_id_ex + 32'd4;
        end
    end
endmodule
