`include "pipeline_if.svh"
`include "riscv_pkg.svh"

module memory_top #(
    parameter DEF_DELAY = 8'd10
)(
    pipeline_if.memory bus
);

    typedef enum logic [2:0] { 
        IDLE, 
        SEND_WRITE, 
        SEND_READ, 
        WAIT_WRITE_READY, 
        WAIT_READ_READY 
    } state_t;

    state_t state, next_state;

    logic start_delay, done_delay;
    logic is_load_store;
    logic is_load;
    logic is_store;

    logic write_done;
    logic read_done;
    logic write_ready;
    logic read_ready; 

    assign bus.mem_stall = (next_state != IDLE);

    assign is_load_store = bus.valid_ex_mem && (bus.is_load_ex_mem || bus.is_store_ex_mem);
    assign is_load       = bus.valid_ex_mem && (bus.is_load_ex_mem);
    assign is_store      = bus.valid_ex_mem && (bus.is_store_ex_mem);

    always_comb begin
        next_state = state;
        unique case (state)
            IDLE: begin 
                if (is_store) begin 
                    next_state = write_ready ? SEND_WRITE : WAIT_WRITE_READY;
                end else if (is_load) begin
                    next_state = read_ready  ? SEND_READ : WAIT_READ_READY;
                end
            end
            SEND_WRITE:       if (write_done)  next_state = IDLE;
            SEND_READ:        if (read_done)   next_state = IDLE;
            WAIT_WRITE_READY: if (write_ready) next_state = SEND_WRITE;
            WAIT_READ_READY:  if (read_ready)  next_state = SEND_READ;
        endcase
    end
 
    logic r_ena, w_ena;

    assign r_ena = (state != SEND_READ)  && (next_state == SEND_READ);
    assign w_ena = (state != SEND_WRITE) && (next_state == SEND_WRITE);
  
    memory_map u_mem (
        .clk   (bus.clk),
        .rst_n(bus.rst_n),
        .r_ena (r_ena),
        .r_addr(bus.alu_result_ex_mem),
        .is_load(is_load),
        .r_data(bus.mem_read_data_mem),
        .w_ena (w_ena),
        .w_addr(bus.alu_result_ex_mem),
        .is_store(is_store),
        .w_data(bus.rs2_data_ex_mem),
        .mem_sz_type (bus.mem_req_type),
        .mem_resp_error (bus.mem_resp_error),
        .write_done(write_done),
        .read_done(read_done),
        .write_ready(write_ready),
        .read_ready(read_ready)
    );

    logic  forward_mem;
    assign forward_mem = ((state == SEND_READ && read_done) || 
                         !bus.is_load_ex_mem)               &&
                         bus.valid_ex_mem                   && 
                         bus.reg_write_ex_mem               &&
                         bus.rd_ex_mem != 5'b0;

    assign bus.rs1_forward_mem = bus.use_rs1_id && (bus.rd_ex_mem == bus.rs1_addr_id) && forward_mem;
    assign bus.rs2_forward_mem = bus.use_rs2_id && (bus.rd_ex_mem == bus.rs2_addr_id) && forward_mem;
                                 
    always_ff @(posedge bus.clk or negedge bus.rst_n) begin
        if (!bus.rst_n) begin
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
            end else if (state == SEND_WRITE && write_done ||
                         state == SEND_READ  && read_done  
            ) begin
                bus.valid_mem_wb     <= 1'b1 && (bus.mem_resp_error == NO_ERROR);
                bus.alu_result_mem_wb <= bus.alu_result_ex_mem;
                bus.mem_read_data_mem_wb <= bus.mem_read_data_mem;
                bus.rd_mem_wb        <= bus.rd_ex_mem;
                bus.is_load_mem_wb   <= bus.is_load_ex_mem;
                bus.reg_write_mem_wb <= bus.reg_write_ex_mem;
            end
        end
    end

endmodule
