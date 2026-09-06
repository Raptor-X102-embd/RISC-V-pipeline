`include "pipeline_if.svh"

module register_file #(
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS = 32
)(
    pipeline_if.regfile bus   
);

    logic [DATA_WIDTH-1:0] regs [NUM_REGS-1:0];
    
    assign bus.rs1_data = (bus.rs1_addr_id == 5'd0) ? 32'd0 : regs[bus.rs1_addr_id];
    assign bus.rs2_data = (bus.rs2_addr_id == 5'd0) ? 32'd0 : regs[bus.rs2_addr_id];
    
    always_ff @(posedge bus.clk or negedge bus.rst_n) begin
        if (!bus.rst_n) begin
            for (int i = 0; i < NUM_REGS; i = i + 1) begin
                regs[i] <= DATA_WIDTH'(0);
            end
        end else if (bus.rd_w_ena_wb&& (bus.rd_addr_wb != 5'd0)) begin
            regs[bus.rd_addr_wb] <= bus.rd_data_wb;
        end
    end
    
endmodule
