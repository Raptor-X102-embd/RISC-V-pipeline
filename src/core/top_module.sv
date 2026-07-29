`include "pipeline_if.svh"

module top_module #(
    parameter INIT_DATA_FILE = "",
    parameter INSTR_WIDTH = 32
)(
    input logic                   clk,
    input logic                   reset
);
    
    pipeline_if bus_if (.clk(clk), .reset(reset));
    
    register_file u_reg_file (.bus(bus_if.regfile));

    fetch_top #(
        .INIT_DATA_FILE(INIT_DATA_FILE)
    ) u_fetch ( 
        .bus(bus_if.fetch)
    );
    decode_top u_decode (.bus(bus_if.decode));
    execute_top u_execute (.bus(bus_if.execute));
    memory_top u_memory (.bus(bus_if.memory));
    writeback_top u_writeback (.bus(bus_if.writeback));

    hazard_detection_unit u_hazard (.bus(bus_if.hazard_unit));
endmodule
