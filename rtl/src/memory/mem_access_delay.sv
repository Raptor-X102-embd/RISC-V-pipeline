module mem_access_delay #(
    parameter MAX_DELAY = 255
)( 
    input  clk,
    input  reset,
    input  logic [7:0] delay,
    input  logic start,
    output logic done
);

    logic [MAX_DELAY:0] shift_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= {{MAX_DELAY{1'b0}}, 1'b0}; 
        end else if (start) begin
            shift_reg <= {{MAX_DELAY{1'b0}}, 1'b1}; 
        end else begin
            shift_reg <= {shift_reg[MAX_DELAY-1:0], 1'b0};
        end
    end

    assign done = shift_reg[delay];
endmodule
