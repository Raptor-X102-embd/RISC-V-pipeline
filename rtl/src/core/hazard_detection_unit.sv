`include "pipeline_if.svh"

module hazard_detection_unit (
    pipeline_if.hazard_unit bus
);

    always_comb begin
        bus.stall = 1'b0;
        if (bus.valid_if_id && bus.valid_ex && bus.reg_write_ex && bus.is_load_ex && (bus.rd_ex != 5'b0)) begin
            if (bus.use_rs1_id && (bus.rs1_addr_id == bus.rd_ex) || 
                bus.use_rs2_id && (bus.rs2_addr_id == bus.rd_ex)
            )
                bus.stall = 1'b1;
        end
    end

endmodule
