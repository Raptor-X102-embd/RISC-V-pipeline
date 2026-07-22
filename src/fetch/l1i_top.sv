module l1i_top #(
    parameter DATA_WIDTH = 8,
    parameter INSTR_SIZE = 4 * DATA_WIDTH,
    parameter L1I_SIZE = 12 // in instructions
)(
    input  logic                  clk,
    input  logic                  areset,

    input  logic                  w_ena,
    input  logic [31:0]           w_addr,
    input  logic [INSTR_SIZE-1:0] w_data,

    //input  logic                  r_ena,
    input  logic  [31:0]          pc,
    output logic [INSTR_SIZE-1:0] instr
);

    localparam ADDR_SHIFT = $clog2(INSTR_SIZE / DATA_WIDTH);

    (* public *) logic [INSTR_SIZE-1:0] l1i [L1I_SIZE-1:0];

    always_comb begin
        instr = l1i[pc >> ADDR_SHIFT];
    end

    always_ff @(posedge clk, posedge areset) begin
        integer i;
        if (areset) begin
            for (i = 0; i < L1I_SIZE; i = i + 1) begin
                l1i[i] <= INSTR_SIZE'(0);
            end
        end else begin
            if (w_ena)
                l1i[w_addr >> ADDR_SHIFT] <= w_data;
        end
    end

endmodule
