`include "pipeline_if.svh"

module fetch_top #(
    parameter INIT_DATA_FILE = "",
    parameter PC_INIT_VALUE = 'h00000000
)(
    pipeline_if.fetch bus
);

    logic [31:0] instr_if;
    logic [31:0] fetch_pc;

    assign fetch_pc = bus.flush ? bus.pc_target : bus.pc;

    l1i_top #(
        .INIT_DATA_FILE(INIT_DATA_FILE)
    ) u_l1i (
        .clk(bus.clk),
        .areset(bus.reset),
        .pc(fetch_pc),   
        .instr(instr_if)
    );

    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (bus.reset) begin
            bus.pc           <= PC_INIT_VALUE;
            bus.valid_if_id  <= 1'b0;
        end else if (bus.flush) begin
            bus.pc           <= bus.pc_target;
            bus.pc_if_id     <= bus.pc_target;
            bus.instr_if_id  <= instr_if;
            bus.valid_if_id  <= 1'b1;
        end else if (!bus.stall && !bus.mem_stall) begin
            // Обычная выборка
            bus.pc_if_id     <= bus.pc;
            bus.instr_if_id  <= instr_if;
            bus.valid_if_id  <= 1'b1;
            bus.pc           <= bus.pc + 4;
        end
    end

endmodule
