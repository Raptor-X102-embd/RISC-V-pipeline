`include "pipeline_if.svh"
`include "decoder_funcs.svh"

module decode_top (
    pipeline_if.decode bus
);
    logic [6:0] opcode;
    assign opcode = bus.instr_if_id[6:0];
    decoded_instr_t dec_instr_id;

    assign bus.rs1_addr = dec_instr_id.rs1;
    assign bus.rs2_addr = dec_instr_id.rs2;

    always_comb begin
        unique case (opcode)
            OPC_OP:     dec_instr_id = decode_fmt_r(bus.instr_if_id);

            OPC_OP_IMM,
            OPC_LOAD,
            OPC_JALR,
            OPC_SYSTEM: dec_instr_id = decode_fmt_i(bus.instr_if_id);

            OPC_STORE:  dec_instr_id = decode_fmt_s(bus.instr_if_id);

            OPC_BRANCH: dec_instr_id = decode_fmt_b(bus.instr_if_id);

            OPC_JAL:    dec_instr_id = decode_fmt_j(bus.instr_if_id);

            OPC_LUI,
            OPC_AUIPC:  dec_instr_id = decode_fmt_u(bus.instr_if_id);

            default:    dec_instr_id.valid = 1'b0;
        endcase
    end

    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (bus.reset || bus.flush) begin
            bus.valid_id_ex <= 1'b0;
        end else if (bus.stall) begin
            bus.valid_id_ex <= 1'b0;
        end else if (!bus.stall && !bus.mem_stall) begin
            if (bus.valid_if_id && dec_instr_id.valid) begin
                bus.valid_id_ex <= 1'b1;
                bus.dec_id_ex   <= dec_instr_id;
                bus.pc_id_ex    <= bus.pc_if_id;
            end else begin
                bus.valid_id_ex <= 1'b0;
            end
        end
    end

    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (!bus.stall && !bus.mem_stall && bus.valid_if_id && dec_instr_id.valid) begin
            unique if (bus.rs1_forward_ex)
                bus.rs1_data_id_ex <= bus.alu_result_ex;
            else if (bus.rs1_forward_mem) begin
                if (bus.is_load_ex_mem)
                    bus.rs1_data_id_ex <= bus.mem_read_data_mem;
                else
                    bus.rs1_data_id_ex <= bus.alu_result_ex_mem; 
            end else if (bus.rs1_forward_wb)
                bus.rs1_data_id_ex <= bus.rd_data_wb;
            else
                bus.rs1_data_id_ex <= bus.rs1_data;

            unique if (bus.rs2_forward_ex)
                bus.rs2_data_id_ex <= bus.alu_result_ex;
            else if (bus.rs2_forward_mem) begin
                if (bus.is_load_ex_mem)
                    bus.rs2_data_id_ex <= bus.mem_read_data_mem;
                else
                    bus.rs2_data_id_ex <= bus.alu_result_ex_mem;
            end else if (bus.rs2_forward_wb)
                bus.rs2_data_id_ex <= bus.rd_data_wb;
            else
                bus.rs2_data_id_ex <= bus.rs2_data;
        end
    end
endmodule
