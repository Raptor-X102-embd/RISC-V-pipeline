`include "pipeline_if.svh"

module hazard_detection_unit (
    pipeline_if.hazard_unit bus
);

    always_comb begin
        bus.stall = 1'b0;

        if (bus.valid_if_id) begin
            if (bus.valid_ex && bus.reg_write_ex && bus.rd_ex != 5'b0 &&
                (bus.rs1_addr == bus.rd_ex || bus.rs2_addr == bus.rd_ex)) begin
                bus.stall = 1'b1;
            end
            if (bus.valid_ex_mem && bus.reg_write_ex_mem && bus.rd_ex_mem != 5'b0 &&
                (bus.rs1_addr == bus.rd_ex_mem || bus.rs2_addr == bus.rd_ex_mem)) begin
                bus.stall = 1'b1;
            end
            if (bus.valid_mem_wb && bus.reg_write_mem_wb && bus.rd_mem_wb != 5'b0 &&
                (bus.rs1_addr == bus.rd_mem_wb || bus.rs2_addr == bus.rd_mem_wb)) begin
                bus.stall = 1'b1;
            end
        end
    end

endmodule
