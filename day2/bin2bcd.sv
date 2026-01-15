`timescale 1ns/1ns

module bin2bcd #(
    parameter PIPELINE_DEPTH = 4, // multiples of 2
    parameter BIN_WIDTH = 64,
    parameter BCD_WIDTH = 80
) (
    input i_clk,
    input i_reset,
    input i_valid,
    input [BIN_WIDTH-1:0] i_bin,
    output o_valid,
    output [BCD_WIDTH-1:0] o_bcd
);

logic [PIPELINE_DEPTH-1:0] d_valid, q_valid;
logic [PIPELINE_DEPTH-1:0][BIN_WIDTH-1:0] d_bin, q_bin; 
// 20 decimal digits, 4 bits each
logic [PIPELINE_DEPTH-1:0][BCD_WIDTH-1:0] d_bcd, q_bcd;

function automatic void add3_and_shift(
    input [BIN_WIDTH-1:0] fi_bin,
    input [BCD_WIDTH-1:0] fi_bcd,
    output [BIN_WIDTH-1:0] fo_bin,
    output [BCD_WIDTH-1:0] fo_bcd
);
    fo_bin = fi_bin;
    fo_bcd = fi_bcd;

    for (int i=0; i<BIN_WIDTH/PIPELINE_DEPTH; i+=1) begin
        for (int j=0; j<BCD_WIDTH; j+=4) begin
            if (fo_bcd[j+:4] > 4)
                fo_bcd[j+:4] += 4'd3;
        end 
        fo_bcd = {fo_bcd[BCD_WIDTH-2:0], fo_bin[BIN_WIDTH-1]};
        fo_bin = fo_bin << 1;
    end
endfunction

always_comb begin : main_logic
    d_valid[0] = i_valid;
    add3_and_shift(.fi_bin(i_bin),
                   .fi_bcd('0),
                   .fo_bin(d_bin[0]),
                   .fo_bcd(d_bcd[0]));
    for (int i=1; i<PIPELINE_DEPTH; i+=1) begin
        d_valid[i] = q_valid[i-1];
        add3_and_shift(.fi_bin(q_bin[i-1]),
                       .fi_bcd(q_bcd[i-1]),
                       .fo_bin(d_bin[i]),
                       .fo_bcd(d_bcd[i]));
    end
end

always_ff @(posedge i_clk) begin : ff_ctrl
    if (i_reset) begin
        q_valid <= '0;
        q_bin <= '0;
        q_bcd <= '0;
    end
    else begin
        q_valid <= d_valid;
        q_bin <= d_bin;
        q_bcd <= d_bcd;
    end
end

assign o_valid = q_valid[PIPELINE_DEPTH-1];
assign o_bcd = q_bcd[PIPELINE_DEPTH-1];

endmodule
