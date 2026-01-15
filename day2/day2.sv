import day2_pkg::*;

module day2 (
    input i_clk,
    input i_reset,
    input i_valid,
    input [BIN_WIDTH-1:0] i_upper_bin,
    input [BIN_WIDTH-1:0] i_lower_bin,
    input i_last,
    output logic o_valid,
    output logic [BIN_WIDTH*2-1:0] o_acc_sum_bin
);

logic bcd_valid;
logic [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] upper_bcd;
logic [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] lower_bcd;

bin2bcd #(
    .PIPELINE_DEPTH(BIN2BCD_PIPE_STAGES),
    .BIN_WIDTH(BIN_WIDTH),
    .BCD_WIDTH(BCD_WIDTH) // 20 digits * 4 bits
) u_upper_bin2bcd (
    .i_clk,
    .i_reset,
    .i_valid,
    .i_bin(i_upper_bin),
    .o_valid(bcd_valid),
    .o_bcd(upper_bcd)
);

bin2bcd #(
    .PIPELINE_DEPTH(BIN2BCD_PIPE_STAGES),
    .BIN_WIDTH(BIN_WIDTH),
    .BCD_WIDTH(BCD_WIDTH) // 20 digits * 4 bits
) u_lower_bin2bcd (
    .i_clk,
    .i_reset,
    .i_valid,
    .i_bin(i_lower_bin),
    .o_valid(), // bcd_valid signal from u_upper_bin2bcd will be used
    .o_bcd(lower_bcd)
);

logic [N_DIGITS:2] per_digit_sum_valid;
logic [N_DIGITS:2][OUT_WIDTH-1:0] per_digit_sum;

generate
    for (genvar digit=MIN_N_DIGITS; digit<=MAX_N_DIGITS; digit++) begin : digit_loop

        logic [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] clipped_u_bcd;
        logic [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] clipped_l_bcd;

        always_comb begin
            // Clip the input range into the current digit range
            clip_to_digit_range(digit, upper_bcd, lower_bcd,
                                clipped_u_bcd, clipped_l_bcd);
        end

        logic base_sequence_found;
        logic [BIN_WIDTH-1:0] base_first_elem_bin;
        logic [BIN_WIDTH-1:0] base_last_elem_bin;
        logic [BIN_WIDTH-1:0] base_n_elems_u_bin;
        logic [BIN_WIDTH-1:0] base_n_elems_l_bin;
        logic base_exclude_first;
        logic base_exclude_last;
        logic base_sum_valid;
        logic [OUT_WIDTH-1:0] base_sum;

        sequence_finder #(
            .N_DIGITS(digit),
            .BIT_PER_DIGIT(BIT_PER_DIGIT),
            .SPLIT_FACTOR(digit),
            .BIN_WIDTH(BIN_WIDTH),
            .BCD2BIN_IN_WIDTH(BCD_WIDTH),
            .BCD2BIN_PIPE_STAGES(BCD2BIN_PIPE_STAGES)
        ) u_sequence_finder_base (
            .i_clk,
            .i_reset,
            .i_valid(bcd_valid),
            .i_lower_bcd(clipped_l_bcd),
            .i_upper_bcd(clipped_u_bcd),
            .o_valid(base_sequence_found),
            .o_first_elem_bin(base_first_elem_bin),
            .o_last_elem_bin(base_last_elem_bin),
            .o_n_elems_low_bin(base_n_elems_l_bin),
            .o_n_elems_up_bin(base_n_elems_u_bin),
            .o_exclude_first(base_exclude_first),
            .o_exclude_last(base_exclude_last)
        );

        seqsum_calculator #(
            .IN_WIDTH(BIN_WIDTH),
            .OUT_WIDTH(OUT_WIDTH) 
        ) u_seqsum_base (
            .i_clk,
            .i_reset,
            .i_valid(base_sequence_found),
            .i_first_elem(base_first_elem_bin),
            .i_last_elem(base_last_elem_bin),
            .i_n_elems_low(base_n_elems_l_bin),
            .i_n_elems_up(base_n_elems_u_bin),
            .i_exclude_first(base_exclude_first),
            .i_exclude_last(base_exclude_last),
            .o_valid(base_sum_valid),
            .o_sum(base_sum)
        );

        logic [N_PRIME_FCTRS-1:0] factor_sum_no_overlap_valid;
        logic [N_PRIME_FCTRS-1:0][OUT_WIDTH-1:0] factor_sum_no_overlap;
        for (genvar i=0; i<N_PRIME_FCTRS; i++) begin : factor_loop
            localparam SPLIT_FACTOR = PRIME_FCTRS[i];
            logic factor_sequence_found;
            logic [BIN_WIDTH-1:0] factor_first_elem_bin;
            logic [BIN_WIDTH-1:0] factor_last_elem_bin;
            logic [BIN_WIDTH-1:0] factor_n_elems_u_bin;
            logic [BIN_WIDTH-1:0] factor_n_elems_l_bin;
            logic factor_exclude_first;
            logic factor_exclude_last;
            logic factor_sum_valid;
            logic [OUT_WIDTH-1:0] factor_sum;

            // Number of digits in the range has to be divisible by factor
            // to split into equal portions
            if (digit%SPLIT_FACTOR == 0 & digit != SPLIT_FACTOR) begin
                sequence_finder #(
                    .N_DIGITS(digit),
                    .BIT_PER_DIGIT(BIT_PER_DIGIT),
                    .SPLIT_FACTOR(SPLIT_FACTOR),
                    .BIN_WIDTH(BIN_WIDTH),
                    .BCD2BIN_IN_WIDTH(BCD_WIDTH),
                    .BCD2BIN_PIPE_STAGES(BCD2BIN_PIPE_STAGES)
                ) u_sequence_finder_factor (
                    .i_clk,
                    .i_reset,
                    .i_valid(bcd_valid),
                    .i_lower_bcd(clipped_l_bcd),
                    .i_upper_bcd(clipped_u_bcd),
                    .o_valid(factor_sequence_found),
                    .o_first_elem_bin(factor_first_elem_bin),
                    .o_last_elem_bin(factor_last_elem_bin),
                    .o_n_elems_low_bin(factor_n_elems_l_bin),
                    .o_n_elems_up_bin(factor_n_elems_u_bin),
                    .o_exclude_first(factor_exclude_first),
                    .o_exclude_last(factor_exclude_last)
                );

                seqsum_calculator #(
                    .IN_WIDTH(BIN_WIDTH),
                    .OUT_WIDTH(OUT_WIDTH) 
                ) u_seqsum_factor (
                    .i_clk,
                    .i_reset,
                    .i_valid(factor_sequence_found),
                    .i_first_elem(factor_first_elem_bin),
                    .i_last_elem(factor_last_elem_bin),
                    .i_n_elems_low(factor_n_elems_l_bin),
                    .i_n_elems_up(factor_n_elems_u_bin),
                    .i_exclude_first(factor_exclude_first),
                    .i_exclude_last(factor_exclude_last),
                    .o_valid(factor_sum_valid),
                    .o_sum(factor_sum)
                );
                
                always_comb begin
                    factor_sum_no_overlap_valid[i] = factor_sum_valid;
                    if (factor_sum_valid)
                        factor_sum_no_overlap[i] = factor_sum - base_sum;
                    else
                        factor_sum_no_overlap[i] = '0;
                end
            end
            else begin
                assign factor_sum_no_overlap_valid[i] = '0;
                assign factor_sum_no_overlap[i] = '0;
            end
        end

        adder_tree #(
            .N_NODES(N_PRIME_FCTRS+1), // + base sum
            .IN_WIDTH(OUT_WIDTH),
            .OUT_WIDTH(OUT_WIDTH)
        ) u_cross_factor_adder (
            .i_clk,
            .i_reset,
            .i_valid((|factor_sum_no_overlap_valid) | base_sum_valid),
            .i_elems({factor_sum_no_overlap, base_sum}),
            .o_valid(per_digit_sum_valid[digit]),
            .o_sum(per_digit_sum[digit])
        );
    end
endgenerate

logic cross_digit_sum_valid;
logic [OUT_WIDTH-1:0] cross_digit_sum;
adder_tree #(
    .N_NODES(N_DIGITS),
    .IN_WIDTH(OUT_WIDTH),
    .OUT_WIDTH(OUT_WIDTH)
) u_cross_digit_adder (
    .i_clk,
    .i_reset,
    .i_valid(|per_digit_sum_valid),
    .i_elems(per_digit_sum),
    .o_valid(cross_digit_sum_valid),
    .o_sum(cross_digit_sum)
);

always_ff @(posedge i_clk) begin : final_sum_accumulator
    if (i_reset) begin
        o_valid <= '0;
        o_acc_sum_bin <= '0;
    end
    else begin
        o_valid <= cross_digit_sum_valid;
        if (cross_digit_sum_valid)
            o_acc_sum_bin <= o_acc_sum_bin + cross_digit_sum;
        else
            o_acc_sum_bin <= '0;
    end
end

endmodule