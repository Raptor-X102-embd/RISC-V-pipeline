`include "pipeline_if.svh"

module memory_top #(
    parameter DEF_DELAY = 8'd10
)(
    pipeline_if.memory bus
);

    typedef enum logic [1:0] { IDLE, SEND, WAIT } state_t;
    state_t state, next_state;

    logic start_delay, done_delay;
    logic is_load_store;

    assign bus.mem_stall = (next_state != IDLE);

    assign is_load_store = bus.valid_ex_mem && (bus.is_load_ex_mem || bus.is_store_ex_mem);

    always_comb begin
        next_state = state;
        unique case (state)
            IDLE: if (is_load_store) next_state = SEND;
            SEND: next_state = WAIT;
            WAIT: if (done_delay) next_state = IDLE;
        endcase
    end

    assign start_delay = (state == SEND);

    mem_access_delay u_delay (
        .clk   (bus.clk),
        .reset (bus.reset),
        .start (start_delay),
        .delay (DEF_DELAY),
        .done  (done_delay)
    );

    logic r_ena, w_ena;
    assign r_ena = (next_state == SEND) && bus.is_load_ex_mem;
    assign w_ena = (next_state == SEND) && bus.is_store_ex_mem;

    memory_map u_mem (
        .clk   (bus.clk),
        .areset(bus.reset),
        .r_ena (r_ena),
        .r_addr(bus.alu_result_ex_mem),
        .r_data(bus.mem_read_data_mem),
        .w_ena (w_ena),
        .w_addr(bus.alu_result_ex_mem),
        .w_data(bus.rs2_data_ex_mem),
        .mem_sz_type (bus.mem_req_type),
        .mem_resp_error (bus.mem_resp_error)
    );

    logic  forward_mem;
    assign forward_mem = (bus.is_load_ex_mem && state == WAIT && done_delay || 
                         !bus.is_load_ex_mem)   &&
                         bus.valid_ex_mem       && 
                         bus.reg_write_ex_mem   &&
                         bus.rd_ex_mem != 5'b0;

    assign bus.rs1_forward_mem = bus.use_rs1_id && (bus.rd_ex_mem == bus.rs1_addr_id) && forward_mem;
    assign bus.rs2_forward_mem = bus.use_rs2_id && (bus.rd_ex_mem == bus.rs2_addr_id) && forward_mem;
                                 
    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (bus.reset) begin
            state <= IDLE;
            bus.valid_mem_wb     <= 1'b0;
            bus.alu_result_mem_wb <= 32'b0;
            bus.rd_mem_wb        <= 5'b0;
            bus.is_load_mem_wb   <= 1'b0;
            bus.reg_write_mem_wb <= 1'b0;
        end else begin
            state <= next_state;

            bus.valid_mem_wb <= 1'b0;

            if (state == IDLE && !is_load_store) begin
                bus.valid_mem_wb     <= bus.valid_ex_mem;
                bus.alu_result_mem_wb <= bus.alu_result_ex_mem;
                bus.rd_mem_wb        <= bus.rd_ex_mem;
                bus.is_load_mem_wb   <= 1'b0;
                bus.reg_write_mem_wb <= bus.reg_write_ex_mem;
            end else if (state == WAIT && done_delay) begin
                bus.valid_mem_wb     <= 1'b1;
                bus.alu_result_mem_wb <= bus.alu_result_ex_mem;
                bus.mem_read_data_mem_wb <= bus.mem_read_data_mem;
                bus.rd_mem_wb        <= bus.rd_ex_mem;
                bus.is_load_mem_wb   <= bus.is_load_ex_mem;
                bus.reg_write_mem_wb <= bus.reg_write_ex_mem;
            end
        end
    end

endmodule
