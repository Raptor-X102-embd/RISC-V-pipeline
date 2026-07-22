`include "pipeline_if.svh"

module fetch_top #(
    parameter PC_INIT_VALUE = 'h00000000
)(
    pipeline_if.fetch             bus,
    input  logic                  w_ena,
    input  logic [31:0]           w_addr,
    input  logic [31:0]           w_data,

    input  logic                  r_ena
);

    logic [31:0] instr_if_id_w;

    l1i_top u_l1i (
        .clk(bus.clk),
        .areset(bus.reset),
        .w_ena(w_ena),
        .w_addr(w_addr),
        .w_data(w_data),
        //.r_ena(r_ena),
        .pc(bus.pc),
        .instr(instr_if_id_w)
    );
    
    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (bus.reset) begin
            bus.pc <= PC_INIT_VALUE;
            bus.valid_if_id <= 1'b0;
        end else if (bus.flush) begin
            bus.pc <= bus.pc_target;
            bus.valid_if_id <= 1'b0;
        end else if (!bus.stall && !bus.mem_stall) begin
            if (r_ena) begin
                bus.pc_if_id   <= bus.pc;
                bus.instr_if_id <= instr_if_id_w;
                bus.valid_if_id <= 1'b1;
                bus.pc <= bus.pc + 4;
            end else begin
                bus.valid_if_id <= 1'b0;
            end
        end
    end

endmodule
