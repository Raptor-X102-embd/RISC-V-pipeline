`include "pipeline_if.svh"

module writeback_top(
    pipeline_if.writeback bus
);

    assign bus.rd_w_ena_wb = bus.reg_write_mem_wb && bus.valid_mem_wb;
    assign bus.rd_addr_wb  = bus.rd_mem_wb;
    assign bus.rd_data_wb  = bus.is_load_mem_wb ? bus.mem_read_data_mem_wb : bus.alu_result_mem_wb;

endmodule
