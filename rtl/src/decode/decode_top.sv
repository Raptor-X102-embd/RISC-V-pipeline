`include "pipeline_if.svh"
`include "decoder_funcs.svh"

module decode_top (
    pipeline_if.decode bus
);
    logic [6:0] opcode;
    assign opcode = bus.instr_if_id[6:0];
    decoded_instr_t dec_instr_id;

    assign bus.rs1_addr_id = dec_instr_id.rs1;
    assign bus.rs2_addr_id = dec_instr_id.rs2;
    assign bus.use_rs1_id =  dec_instr_id.use_rs1;
    assign bus.use_rs2_id =  dec_instr_id.use_rs2;

    always_comb begin
        dec_instr_id = '0;
        dec_instr_id.opcode = bus.instr_if_id[6:0];
        dec_instr_id.rd     = bus.instr_if_id[11:7];
        dec_instr_id.rs1    = bus.instr_if_id[19:15];
        dec_instr_id.rs2    = bus.instr_if_id[24:20];
        dec_instr_id.funct3 = bus.instr_if_id[14:12];
        dec_instr_id.funct7 = bus.instr_if_id[31:25];

        unique case (opcode)
            OPC_OP:     decode_fmt_r(dec_instr_id, bus.instr_if_id);

            OPC_OP_IMM,
            OPC_LOAD,
            OPC_JALR,
            OPC_SYSTEM: decode_fmt_i(dec_instr_id, bus.instr_if_id);

            OPC_STORE:  decode_fmt_s(dec_instr_id, bus.instr_if_id);

            OPC_BRANCH: decode_fmt_b(dec_instr_id, bus.instr_if_id);

            OPC_JAL:    decode_fmt_j(dec_instr_id, bus.instr_if_id);

            OPC_LUI,
            OPC_AUIPC:  decode_fmt_u(dec_instr_id, bus.instr_if_id);

            default:    dec_instr_id.valid = 1'b0;
        endcase
    end

    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (bus.reset || bus.flush) begin
            bus.valid_id_ex <= 1'b0;
            bus.dec_id_ex <= decoded_instr_t'(0);
            bus.pred_taken_id_ex <= 1'b0;
            bus.pred_target_id_ex <= 32'b0;
            // TODO: remove if everything depends on valid.
            bus.pc_id_ex <= 32'b0;
        end else if (bus.stall) begin
            bus.valid_id_ex <= 1'b0;
        end else if (!bus.stall && !bus.mem_stall) begin
            if (bus.valid_if_id && dec_instr_id.valid) begin
                bus.valid_id_ex <= 1'b1;
                bus.dec_id_ex   <= dec_instr_id;
                bus.pc_id_ex    <= bus.pc_if_id;
                bus.pred_taken_id_ex <= bus.pred_taken_if_id;
                bus.pred_target_id_ex <= bus.pred_target_if_id;
            end else begin
                bus.valid_id_ex <= 1'b0;
            end
        end
    end

    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (!bus.stall && !bus.mem_stall && bus.valid_if_id && dec_instr_id.valid) begin
            priority if (bus.rs1_forward_ex)
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

            priority if (bus.rs2_forward_ex)
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
