`include "riscv_pkg.svh"
`include "axi4_if.svh"
`include "axi4_pkg.svh"

module memory_map #(
    parameter MEM_SIZE = 1024,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter USER_WIDTH = 0,
    parameter MAX_OUTSTANDING = 16,

    parameter MAX_DATA_W = DATA_WIDTH,
    parameter MAX_DATA_R = DATA_WIDTH,
    parameter MIN_ADDR   = 32'h00000000
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  r_ena,
    input  logic [31:0]           r_addr,
    input  logic                  is_load,
    output logic [MAX_DATA_R-1:0] r_data,

    input  logic                  w_ena,
    input  logic [31:0]           w_addr,
    input  logic                  is_store,
    input  logic [MAX_DATA_W-1:0] w_data,
    input  memory_size_t          mem_sz_type,
    output logic                  write_done,
    output logic                  read_done,
    output logic                  write_ready,
    output logic                  read_ready, 
    output mem_resp_err_t         mem_resp_error
);

    localparam MAX_ADDR = MIN_ADDR + MEM_SIZE - 1;

    localparam BYTE = 8;
    localparam HALFWORD = 16;
    localparam WORD = 32;

    logic                  start_read;
    logic [ID_WIDTH-1:0]   read_id;
    logic [ADDR_WIDTH-1:0] read_addr;
    logic [7:0]            read_len;
    logic [2:0]            read_size;
    logic [1:0]            read_burst;
    logic [ID_WIDTH-1:0]   read_rid_out;
    logic [1:0]            read_resp_out;
    logic [DATA_WIDTH-1:0] read_data_out;
    logic                  read_done_axi;

    logic                  start_write;
    logic [ID_WIDTH-1:0]   write_id;
    logic [ADDR_WIDTH-1:0] write_addr;
    logic [7:0]            write_len;
    logic [2:0]            write_size;
    logic [1:0]            write_burst;
    logic [DATA_WIDTH-1:0] write_data;
    logic [ID_WIDTH-1:0]   write_id_out;
    logic [1:0]            write_resp_out;
    logic                  write_done_axi;

    logic                  r_par_valid;
    logic                  w_par_valid;
    logic                  w_size_valid;
    logic                  r_size_valid;
    logic                  w_addr_valid;
    logic                  r_addr_valid;

    axi4_if #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ID_WIDTH(ID_WIDTH),
      .USER_WIDTH(USER_WIDTH)
    ) axi_bus (
      .ACLK(clk),
      .ARESETn(rst_n)
    );
    
    axi4_master #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ID_WIDTH(ID_WIDTH),
      .MAX_OUTSTANDING(MAX_OUTSTANDING)
    ) u_master (
      .bus(axi_bus),
      .start_read(start_read),
      .read_id(read_id),
      .read_addr(read_addr),
      .read_len(read_len),
      .read_size(read_size),
      .read_burst(read_burst),
      .start_write(start_write),
      .write_id(write_id),
      .write_addr(write_addr),
      .write_len(write_len),
      .write_size(write_size),
      .write_burst(write_burst),
      .write_data(write_data),
      .read_rid_out(read_rid_out),
      .read_resp_out(read_resp_out),
      .read_data_out(read_data_out),
      .read_done(read_done_axi),
      .read_ready(read_ready),
      .write_id_out(write_id_out),
      .write_resp_out(write_resp_out),
      .write_done(write_done_axi),
      .write_ready(write_ready)
    ); 

    axi4_slave #(
      .MEM_SIZE(MEM_SIZE),
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ID_WIDTH(ID_WIDTH),
      .MIN_ADDR(MIN_ADDR)
    ) u_slave (
      .bus(axi_bus)
    );

    // TODO: make multiple errors
    mem_resp_err_t mem_resp_error_comb;
    mem_resp_err_t mem_resp_error_reg;

    function automatic logic valid_addr(input logic [31:0] addr);
        // Disabled only for MIN_ADDR == 0
        /* verilator lint_off UNSIGNED */
        return (addr >= MIN_ADDR && addr <= MAX_ADDR);
        /* verilator lint_off UNSIGNED */
    endfunction

    assign start_read    = r_ena && r_params_ok;
    assign start_write   = w_ena && w_params_ok;

    assign write_data    = w_data;

    assign read_id = '0;
    assign read_addr = r_addr;
    assign read_len = '0;
    assign read_size = 3'b010;
    assign read_burst = INCR;

    assign write_id = '0;
    assign write_addr = w_addr;
    assign write_len = '0;
    assign write_burst = INCR;

    logic r_params_ok, w_params_ok;
    assign r_params_ok = r_size_valid && r_addr_valid;
    assign w_params_ok = w_size_valid && w_addr_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_par_valid <= 1'b1;
        end else begin
            if (r_params_ok) begin
                r_par_valid <= 1'b1;
            end else begin
                if (r_par_valid) begin
                    r_par_valid <= 1'b0;
                end else begin
                    r_par_valid <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_par_valid <= 1'b1;
        end else begin
            if (w_params_ok) begin
                w_par_valid <= 1'b1;
            end else begin
                if (w_par_valid) begin
                    w_par_valid <= 1'b0;
                end else begin
                    w_par_valid <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_resp_error_reg <= NO_ERROR;
        end else begin
            mem_resp_error_reg <= mem_resp_error_comb;
        end
    end

    assign read_done  = r_par_valid ? read_done_axi  : 1'b1;
    assign write_done = w_par_valid ? write_done_axi : 1'b1;

    always_comb begin
        w_size_valid = 1'b1;
        r_size_valid = 1'b1;
        w_addr_valid = 1'b1;
        r_addr_valid = 1'b1;
        mem_resp_error_comb = NO_ERROR;
        if (is_load) begin
            r_addr_valid = valid_addr(r_addr);
            case (mem_sz_type)
                LOAD_LB:  r_data = { {(MAX_DATA_R-BYTE)    {read_data_out[BYTE-1]}    }, read_data_out[BYTE-1:0]   };
                LOAD_LH:  r_data = { {(MAX_DATA_R-HALFWORD){read_data_out[HALFWORD-1]}}, read_data_out[HALFWORD-1:0] };
                LOAD_LW:  r_data = { {(MAX_DATA_R-WORD)    {read_data_out[WORD-1]}    }, read_data_out[WORD-1:0]     }; 
                LOAD_LBU: r_data = { {(MAX_DATA_R-BYTE)    {1'b0}                   }, read_data_out[BYTE-1:0]   };
                LOAD_LHU: r_data = { {(MAX_DATA_R-HALFWORD){1'b0}                   }, read_data_out[HALFWORD-1:0] };
                default: begin 
                    mem_resp_error_comb = UNKNOWN_MEM_SIZE;
                    r_size_valid = 1'b0;
                    r_data = 'x;
                end
            endcase

            if (!r_addr_valid)
                mem_resp_error_comb = ADDR_ERROR;
        end

        if (is_store) begin
            w_addr_valid = valid_addr(w_addr);
            case (mem_sz_type)
                STORE_SB: write_size = 3'b000;
                STORE_SH: write_size = 3'b001;
                STORE_SW: write_size = 3'b010;
                default: begin 
                    write_size = 3'b000;
                    mem_resp_error_comb = UNKNOWN_MEM_SIZE;
                    w_size_valid = 1'b0;
                end
            endcase
            
            if (!w_addr_valid)
                mem_resp_error_comb = ADDR_ERROR;
        end
    end

    assign mem_resp_error = mem_resp_error_reg;

endmodule
