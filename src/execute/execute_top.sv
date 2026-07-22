`include "pipeline_if.svh"

module execute_top(
    pipeline_if.execute bus
);

    logic [31:0] alu_result;
    
    alu_top u_alu (
        .bus(bus),
        .rs1_data(bus.rs1_data_id_ex),
        .rs2_data(bus.rs2_data_id_ex),
        .pc(bus.pc_id_ex),
        .alu_result(alu_result)
    );

    count_pc_target u_cnt_pc(
        .bus(bus)
    );

    always_comb begin
        bus.rd_ex        = bus.dec_id_ex.rd;
        bus.reg_write_ex = bus.dec_id_ex.reg_write;
        bus.valid_ex     = bus.valid_id_ex;
    end

    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (bus.reset) begin
            bus.valid_ex_mem <= 1'b0;
        end else begin
            if (!bus.mem_stall) begin
                bus.valid_ex_mem <= bus.valid_id_ex;
                bus.alu_result_ex_mem <= alu_result;
                bus.rd_ex_mem <= bus.dec_id_ex.rd;
                bus.rs2_data_ex_mem <= bus.rs2_data_id_ex; // store rs2, imm(rs1)
                bus.is_load_ex_mem <= bus.dec_id_ex.is_load;
                bus.is_store_ex_mem <= bus.dec_id_ex.is_store;
                bus.reg_write_ex_mem <= bus.valid_id_ex && bus.dec_id_ex.reg_write;
                bus.mem_req_type <= bus.dec_id_ex.mem_sz_type;
            end 
            // else begin
            //     bus.valid_ex_mem <= 1'b0;
            // end
        end
    end

endmodule
