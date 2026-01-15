module sequence_finder #(
    parameter N_DIGITS = 20,
    parameter BIT_PER_DIGIT = 4,
    parameter SPLIT_FACTOR = 20,
    parameter BIN_WIDTH = 64,
    parameter BCD2BIN_IN_WIDTH = 80,
    parameter BCD2BIN_PIPE_STAGES = 20
) (
    input i_clk,
    input i_reset,
    input i_valid,
    input [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] i_lower_bcd,
    input [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] i_upper_bcd,
    output o_valid,
    output [BIN_WIDTH-1:0] o_first_elem_bin,
    output [BIN_WIDTH-1:0] o_last_elem_bin,
    output [BIN_WIDTH-1:0] o_n_elems_low_bin,
    output [BIN_WIDTH-1:0] o_n_elems_up_bin,
    output o_exclude_first,
    output o_exclude_last
);

localparam SPLIT_WIDTH = N_DIGITS / SPLIT_FACTOR;

logic [SPLIT_WIDTH-1:0][BIT_PER_DIGIT-1:0] split_bcd_u;
logic [SPLIT_WIDTH-1:0][BIT_PER_DIGIT-1:0] split_bcd_l;
logic [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] extrapol_bcd_u; 
logic [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] extrapol_bcd_l;

logic exclude_first;
logic exclude_last;
logic [BCD2BIN_PIPE_STAGES-1:0] q_exclude_first;
logic [BCD2BIN_PIPE_STAGES-1:0] q_exclude_last;

logic bcd2bin_done;

always_comb begin : get_sequence_range
    // 1) Split the number into *split_factor* subnumbers.
    // 2) Extrapolate the most significant subnumber.
    // For example, 141512, split into 3, we get
    // 14-15-12. Extrapolate 14, we get 14-14-14.
    // If the extrapolated number > i_upper_bcd,
    // the extrapolated number should be excluded from
    // the arithmetic progression.
    split_bcd_u = i_upper_bcd[N_DIGITS-1-:SPLIT_WIDTH];
    extrapol_bcd_u = {SPLIT_FACTOR{split_bcd_u}};
    if (extrapol_bcd_u > i_upper_bcd)
        exclude_last = 1'b1;
    else
        exclude_last = 1'b0;

    // Similar to upper bound, but for lower bound
    // the extrapolated number is excluded if it is
    // lower than the lower bound
    split_bcd_l = i_lower_bcd[N_DIGITS-1-:SPLIT_WIDTH];
    extrapol_bcd_l = {SPLIT_FACTOR{split_bcd_l}};
    if (extrapol_bcd_l < i_lower_bcd)
        exclude_first = 1'b1;
    else
        exclude_first = 1'b0;
end

always_ff @(posedge i_clk) begin
    if (i_reset) begin
        q_exclude_first <= '0;
        q_exclude_last  <= '0;
    end
    else begin
        q_exclude_first <= (q_exclude_first << 1) |
                            exclude_first;
        q_exclude_last  <= (q_exclude_last << 1) |
                            exclude_last;
    end
end

bcd2bin #(
    .PIPELINE_DEPTH(BCD2BIN_PIPE_STAGES),
    .BCD_WIDTH(BCD2BIN_IN_WIDTH),
    .BIN_WIDTH(BIN_WIDTH)
) u_bcd2bin_last_elem (
    .i_clk,
    .i_reset,
    .i_valid,
    .i_bcd(extrapol_bcd_u),
    .o_valid(bcd2bin_done),
    .o_bin(o_last_elem_bin)
);

bcd2bin #(
    .PIPELINE_DEPTH(BCD2BIN_PIPE_STAGES),
    .BCD_WIDTH(BCD2BIN_IN_WIDTH),
    .BIN_WIDTH(BIN_WIDTH)
) u_bcd2bin_first_elem (
    .i_clk,
    .i_reset,
    .i_valid, 
    .i_bcd(extrapol_bcd_l),
    // valid signal from u_bcd2bin_last_elem is used
    .o_valid(),
    .o_bin(o_first_elem_bin)
);

bcd2bin #(
    .PIPELINE_DEPTH(BCD2BIN_PIPE_STAGES),
    .BCD_WIDTH(BCD2BIN_IN_WIDTH),
    .BIN_WIDTH(BIN_WIDTH)
) u_bcd2bin_element_num_u (
    .i_clk,
    .i_reset,
    .i_valid,
    .i_bcd(split_bcd_u),
    // valid signal from u_bcd2bin_last_elem is used
    .o_valid(),
    .o_bin(o_n_elems_up_bin)
);

bcd2bin #(
    .PIPELINE_DEPTH(BCD2BIN_PIPE_STAGES),
    .BCD_WIDTH(BCD2BIN_IN_WIDTH),
    .BIN_WIDTH(BIN_WIDTH)
) u_bcd2bin_element_num_l (
    .i_clk,
    .i_reset,
    .i_valid,
    .i_bcd(split_bcd_l),
    // valid signal from u_bcd2bin_last_elem is used
    .o_valid(),
    .o_bin(o_n_elems_low_bin)
);

assign o_valid = (o_last_elem_bin >= o_first_elem_bin) & 
                 bcd2bin_done;
assign o_exclude_first = q_exclude_first[BCD2BIN_PIPE_STAGES-1];
assign o_exclude_last  = q_exclude_last[BCD2BIN_PIPE_STAGES-1];

endmodule