`include "riscv_pkg.svh"

module memory_map #(
    parameter DATA_WIDTH = 8,
    parameter MAX_DATA_W = DATA_WIDTH * 4,
    parameter MAX_DATA_R = DATA_WIDTH * 4,
    parameter MIN_ADDR   = 32'h00000000,
    parameter MAX_ADDR   = 32'h000000F8
)(
    input  logic                  clk,
    input  logic                  areset,
    input  logic                  r_ena,
    input  logic [31:0]           r_addr,
    output logic [MAX_DATA_R-1:0] r_data,
    input  logic                  w_ena,
    input  logic [31:0]           w_addr,
    input  logic [MAX_DATA_W-1:0] w_data,
    input  memory_size_t          mem_sz_type,
    output mem_resp_err_t         mem_resp_error
);

    logic [DATA_WIDTH-1:0] mem [MAX_ADDR:MIN_ADDR];
    mem_resp_err_t mem_resp_error_reg;

    function automatic logic valid_addr(input logic [31:0] addr);
        // Disabled only for MIN_ADDR == 0
        /* verilator lint_off UNSIGNED */
        return (addr >= MIN_ADDR && addr <= MAX_ADDR);
        /* verilator lint_off UNSIGNED */
    endfunction

    function automatic logic [DATA_WIDTH-1:0] pack_byte(
        input logic [MAX_DATA_W-1:0] data,
        input int                    byte_idx
    );
        return data[byte_idx*DATA_WIDTH +: DATA_WIDTH];
    endfunction

    function automatic logic [MAX_DATA_R-1:0] unpack_read_data(
        input memory_size_t sz,
        input logic [31:0] addr
    );
        logic [MAX_DATA_R-1:0] res;
        case (sz)
            LOAD_LB:  res = { {(MAX_DATA_R-DATA_WIDTH){mem[addr][DATA_WIDTH-1]}}, mem[addr] };
            LOAD_LH:  res = { {(MAX_DATA_R-2*DATA_WIDTH){mem[addr+1][DATA_WIDTH-1]}}, mem[addr+1], mem[addr] };
            LOAD_LW:  res = { mem[addr+3], mem[addr+2], mem[addr+1], mem[addr] };
            LOAD_LBU: res = { {(MAX_DATA_R-DATA_WIDTH){1'b0}}, mem[addr] };
            LOAD_LHU: res = { {(MAX_DATA_R-2*DATA_WIDTH){1'b0}}, mem[addr+1], mem[addr] };
            default:  res = 'x;
        endcase
        return res;
    endfunction

    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            for (int i = MIN_ADDR; i <= MAX_ADDR; i++)
                mem[i] <= '0;
            r_data <= '0;
            mem_resp_error_reg <= NO_ERROR;
        end else begin
            if (w_ena && valid_addr(w_addr)) begin
                case (mem_sz_type)
                    STORE_SB: mem[w_addr] <= pack_byte(w_data, 0);
                    STORE_SH: begin
                        mem[w_addr]   <= pack_byte(w_data, 0);
                        mem[w_addr+1] <= pack_byte(w_data, 1);
                    end
                    STORE_SW: begin
                        mem[w_addr]   <= pack_byte(w_data, 0);
                        mem[w_addr+1] <= pack_byte(w_data, 1);
                        mem[w_addr+2] <= pack_byte(w_data, 2);
                        mem[w_addr+3] <= pack_byte(w_data, 3);
                    end
                    default: mem_resp_error_reg <= UNKNOWN_MEM_SIZE;
                endcase
            end

            if (r_ena) begin
                if (!valid_addr(r_addr)) begin
                    mem_resp_error_reg <= ADDR_ERROR;
                    r_data <= '0;
                end else begin
                    if (mem_sz_type inside {LOAD_LB, LOAD_LH, LOAD_LW, LOAD_LBU, LOAD_LHU}) begin
                        r_data <= unpack_read_data(mem_sz_type, r_addr);
                    end else begin
                        mem_resp_error_reg <= UNKNOWN_MEM_SIZE;
                        r_data <= '0;
                    end
                end
            end
        end
    end

    assign mem_resp_error = mem_resp_error_reg;

endmodule
