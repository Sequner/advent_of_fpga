module adder_tree #(
    parameter N_NODES = 32,
    parameter IN_WIDTH = 128,
    // don't care about overflow
    // since it shouldn't happen for the current problem
    parameter OUT_WIDTH = 128
) (
    input i_clk,
    input i_reset,
    input i_valid,
    input [N_NODES-1:0][IN_WIDTH-1:0] i_elems,
    output o_valid,
    output [OUT_WIDTH-1:0] o_sum
);

// if N_NODES is not a multiple of 2
// approximate to the closest upper multiple of 2
localparam POWER2_N_NODES = (&(N_NODES-1)) ? N_NODES : 
                                             1<<($clog2(N_NODES)+1);

logic [POWER2_N_NODES-1:0][OUT_WIDTH-1:0] partial_sums;
logic [OUT_WIDTH-1:0] q_sum;
logic q_valid;

always_comb begin
    for (int i=0; i<POWER2_N_NODES; i++) begin
        if (i < N_NODES)
            partial_sums[i] = i_elems[i];
        else
            partial_sums[i] = '0;
    end

    for (int i=0; i<$clog2(POWER2_N_NODES); i++) begin
        for (int j=0; j<POWER2_N_NODES/2; j++) begin
            if (j % (1<<(i+1)) == 0)
                partial_sums[j] += partial_sums[j+(1<<i)];
        end
    end
end

always_ff @(posedge i_clk) begin
    if (i_reset) begin
        q_valid <= '0;
        q_sum <= '0;
    end
    else begin
        q_valid <= i_valid;
        q_sum <= partial_sums[0];
    end
end

assign o_valid = q_valid;
assign o_sum = q_sum;
    
endmodule