`include "pipeline_if.svh"

module fetch_top #(
    parameter INIT_DATA_FILE = "",
    parameter PC_INIT_VALUE = 'h00000000,
    parameter L1I_SIZE = 1000
)(
    pipeline_if.fetch bus
);

    logic [31:0] instr_if;

    l1i_top #(
        .INIT_DATA_FILE(INIT_DATA_FILE),
        .L1I_SIZE(L1I_SIZE)
    ) u_l1i (
        .clk(bus.clk),
        .areset(bus.reset),
        .pc(bus.pc),   
        .instr(instr_if)
    );

    always_comb begin
        bus.pc_if = bus.pc + 4;
        if (bus.flush && bus.branch_taken) begin
            bus.pc_if = bus.pc_target;
        end else if (bus.pred_taken) begin
            bus.pc_if = bus.pred_target;
        end
    end

    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (bus.reset) begin
            bus.pc           <= PC_INIT_VALUE;
            bus.valid_if_id  <= 1'b0;
            bus.pred_taken_if_id  <= 1'b0;
            bus.pred_target_if_id <= 32'b0;
            //bus.pc_if_id     <= PC_INIT_VALUE;
        end else if (bus.flush) begin
            bus.pc           <= bus.pc_if;
            bus.valid_if_id  <= 1'b0;
            bus.pred_taken_if_id  <= 1'b0;
            bus.pred_target_if_id <= 32'b0;
            //bus.pc_if_id     <= bus.pc_target;
        end else if (!bus.stall && !bus.mem_stall) begin
            bus.pc_if_id     <= bus.pc;
            bus.pc           <= bus.pc_if;
            bus.instr_if_id  <= instr_if;
            bus.pred_taken_if_id  <= bus.pred_taken;
            bus.pred_target_if_id <= bus.pred_target;
            bus.valid_if_id  <= bus.pc_if <= L1I_SIZE * 4;
        end
    end

endmodule
