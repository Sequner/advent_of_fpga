module seqsum_calculator #(
    parameter IN_WIDTH = 64,
    parameter OUT_WIDTH = 128 
) (
    input i_clk,
    input i_reset,
    input i_valid,
    input [IN_WIDTH-1:0] i_first_elem,
    input [IN_WIDTH-1:0] i_last_elem,
    input [IN_WIDTH-1:0] i_n_elems_low,
    input [IN_WIDTH-1:0] i_n_elems_up,
    input i_exclude_first,
    input i_exclude_last,
    output o_valid,
    output [OUT_WIDTH-1:0] o_sum
);

// Pipeline buffers
logic [2:0] q_valid;
logic [1:0][IN_WIDTH-1:0] q_first_elem;
logic [1:0][IN_WIDTH-1:0] q_last_elem;
logic [1:0] q_exclude_first;
logic [1:0] q_exclude_last;

// Sequence sum of arithmetic progression
// can be calculated as: n_elems*(last_elem+first_elem)/2
logic [IN_WIDTH:0] n_elems;
logic [IN_WIDTH:0] add_elems;
logic [OUT_WIDTH-1:0] total_sum;
// in case first and/or last elem should be excluded
// from the sequence
logic [OUT_WIDTH-1:0] sum_excluded;

always_ff @(posedge i_clk) begin
    if (i_reset) begin
        q_valid <= '0;
        q_first_elem <= '0;
        q_last_elem <= '0;
        q_exclude_first <= '0;
        q_exclude_last <= '0;

        n_elems <= '0;
        add_elems <= '0;
        total_sum <= '0;
        sum_excluded <= '0;
    end
    else begin
        // can add if i_valid for power efficiency
        // but it's a conceptual design
        q_valid <= {q_valid[1:0], i_valid};
        q_first_elem <= {q_first_elem[0], i_first_elem};
        q_last_elem <= {q_last_elem[0], i_last_elem};
        q_exclude_first <= {q_exclude_first[0], i_exclude_first};
        q_exclude_last <= {q_exclude_last[0], i_exclude_last};

        n_elems <= i_n_elems_up - i_n_elems_low + 1;
        add_elems <= i_first_elem + i_last_elem;
        total_sum <= (n_elems * add_elems) >> 1; // >> 1 as divide by 2

        if (q_valid[1]) begin // if not valid, ignore the sum
            if (q_exclude_first[1] * q_exclude_last[1])
                sum_excluded <= total_sum - (q_first_elem[1]+q_last_elem[1]);
            else if (q_exclude_first[1])
                sum_excluded <= total_sum - q_first_elem[1];
            else if (q_exclude_last[1])
                sum_excluded <= total_sum - q_last_elem[1];
            else
                sum_excluded <= total_sum;
        end
    end
end

assign o_valid = q_valid[2];
assign o_sum = sum_excluded;

endmodule