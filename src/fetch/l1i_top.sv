module l1i_top #(
    parameter INIT_DATA_FILE = "",
    parameter DATA_WIDTH = 8,
    parameter INSTR_SIZE = 4 * DATA_WIDTH,
    parameter L1I_SIZE = 12 // in instructions
)(
    input  logic                  clk,
    input  logic                  areset,

    input  logic  [31:0]          pc,
    output logic [INSTR_SIZE-1:0] instr
);

    localparam ADDR_SHIFT = $clog2(INSTR_SIZE / DATA_WIDTH);

    logic [INSTR_SIZE-1:0] l1i [L1I_SIZE-1:0];

    always_comb begin
        instr = l1i[pc >> ADDR_SHIFT];
    end

    always_ff @(posedge clk, posedge areset) begin
        if (areset) begin
            if (INIT_DATA_FILE != "")
                $readmemh(INIT_DATA_FILE, l1i);
        end
    end

endmodule
