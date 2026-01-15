module bcd2bin #(
    // N_DIGIT must be divisible by pipeline depth
    parameter PIPELINE_DEPTH = 20,
    parameter BCD_WIDTH = 80,
    parameter BIN_WIDTH = 64,
    localparam BIT_PER_DIGIT = 4,
    localparam N_DIGITS = BCD_WIDTH/BIT_PER_DIGIT,
    localparam N_DIGITS_PER_STAGE = N_DIGITS/PIPELINE_DEPTH
) (
    input i_clk,
    input i_reset,
    input i_valid,
    input [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] i_bcd,
    output o_valid,
    output [BIN_WIDTH-1:0] o_bin
);

logic [PIPELINE_DEPTH-1:0] d_valid, q_valid;
logic [PIPELINE_DEPTH-1:0][N_DIGITS-1:0][BIT_PER_DIGIT-1:0] d_bcd, q_bcd;
logic [PIPELINE_DEPTH-1:0][BIN_WIDTH-1:0] d_bin, q_bin;

function automatic [BIN_WIDTH-1:0] mac_and_shift (
    input [N_DIGITS_PER_STAGE-1:0][BIT_PER_DIGIT-1:0] fi_bcd,
    input [BIN_WIDTH-1:0] fi_bin
);
    mac_and_shift = fi_bin*(10**N_DIGITS_PER_STAGE);
    for (int i=0; i<N_DIGITS_PER_STAGE; i+=1) begin
        mac_and_shift += fi_bcd[i]*(10**i);        
    end
endfunction

always_comb begin
    int offset;
    d_valid = (q_valid << 1) | i_valid;
    d_bcd[0] = i_bcd;
    d_bin[0] = mac_and_shift(i_bcd[N_DIGITS-1-:N_DIGITS_PER_STAGE],
                             '0);
    for (int i=1; i<PIPELINE_DEPTH; i++) begin
        offset = N_DIGITS-1-i*N_DIGITS_PER_STAGE;
        d_bcd[i] = q_bcd[i-1];
        d_bin[i] = mac_and_shift(q_bcd[i-1][offset-:N_DIGITS_PER_STAGE], 
                                 q_bin[i-1]);
    end
end

always_ff @(posedge i_clk) begin
    if (i_reset) begin
        q_valid <= '0;
        q_bcd <= '0;
        q_bin <= '0;
    end
    else begin
        q_valid <= d_valid;
        q_bcd <= d_bcd;
        q_bin <= d_bin;
    end
end

assign o_valid = q_valid[PIPELINE_DEPTH-1];
assign o_bin = q_bin[PIPELINE_DEPTH-1];

initial begin
    // N_DIGITS must be divisible by pipeline depth
    assert(N_DIGITS%PIPELINE_DEPTH==0);
end

endmodule