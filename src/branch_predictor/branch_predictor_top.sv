`include "pipeline_if.svh"

module branch_predictor_top #(
    parameter BTB_SIZE = 64
)(
    pipeline_if.branch_predictor bus
);

    localparam int INDEX_BITS = $clog2(BTB_SIZE);
    localparam int TAG_BITS   = 30 - INDEX_BITS; // 30 - pc size without 2 LSB (always 0)

    typedef struct packed {
        logic        valid;
        logic [TAG_BITS-1:0] tag;
        logic [31:0] target;
        logic [1:0]  pht;
    } btb_entry_t;

    typedef enum logic [1:0] { SNT, WNT, WT, ST } predict_strenght_t; // cant make up shorter form :(

    btb_entry_t btb [BTB_SIZE-1:0];

    logic [INDEX_BITS-1:0] idx;
    logic [TAG_BITS-1:0]   tag;
    btb_entry_t                read_entry;

    logic [INDEX_BITS-1:0] upd_idx;
    logic [TAG_BITS-1:0]   upd_tag;
    btb_entry_t                new_entry;

    logic tag_hit;

    assign idx = bus.pc[INDEX_BITS+1:2];
    assign tag = bus.pc[31:INDEX_BITS+2];

    assign read_entry = btb[idx];

    assign tag_hit = read_entry.valid && (read_entry.tag == tag);

    assign bus.pred_taken  = tag_hit && read_entry.pht[1]; // is equal to read_entry.pht >= WT 
    assign bus.pred_target = read_entry.target;

    assign upd_idx = bus.pc_id_ex[INDEX_BITS+1:2];
    assign upd_tag = bus.pc_id_ex[31:INDEX_BITS+2];

    // misprediction
    assign bus.flush = bus.valid_id_ex && ((bus.branch_taken != bus.pred_taken_id_ex) || 
                       (bus.branch_taken && (bus.pc_target != bus.pred_target_id_ex)));

    always_comb begin
        new_entry = btb[upd_idx];
        if (bus.update_valid) begin
            new_entry.valid = 1'b1;
            new_entry.tag   = upd_tag;
            new_entry.target = bus.pc_target;
            if (bus.branch_taken)
                new_entry.pht = (new_entry.pht < ST)  ? new_entry.pht + 1 : 3;
            else
                new_entry.pht = (new_entry.pht > SNT) ? new_entry.pht - 1 : 0;
        end
    end

    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (bus.reset) begin
            for (int i = 0; i < BTB_SIZE; i++) begin
                btb[i] <= btb_entry_t'(0);
                btb[i].pht <= WT;
            end
        end else begin
            if (bus.update_valid) begin
                btb[upd_idx] <= new_entry;
            end
        end
    end
endmodule
