`include "pipeline_if.svh"

module writeback_top(
    pipeline_if.writeback bus
);
    logic  forward_wb;
    assign forward_wb =  bus.valid_mem_wb       && 
                         bus.reg_write_mem_wb   &&
                         bus.rd_mem_wb != 5'b0;

    assign bus.rs1_forward_wb = bus.use_rs1_id && (bus.rd_mem_wb == bus.rs1_addr_id) && forward_wb;
    assign bus.rs2_forward_wb = bus.use_rs2_id && (bus.rd_mem_wb == bus.rs2_addr_id) && forward_wb;

    assign bus.rd_w_ena_wb = bus.reg_write_mem_wb && bus.valid_mem_wb;
    assign bus.rd_addr_wb  = bus.rd_mem_wb;
    assign bus.rd_data_wb  = bus.is_load_mem_wb ? bus.mem_read_data_mem_wb : bus.alu_result_mem_wb;

endmodule
