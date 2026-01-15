package day2_pkg;

timeunit 1ns;
timeprecision 1ns;

localparam BIN_WIDTH = 36;
localparam BCD_WIDTH = 40;
localparam OUT_WIDTH = BIN_WIDTH*2;

localparam BIT_PER_DIGIT = 4;
localparam N_DIGITS = BCD_WIDTH / BIT_PER_DIGIT;
localparam W_DIGITS = $clog2(N_DIGITS)+1;

localparam BIN2BCD_PIPE_STAGES = BIN_WIDTH;
localparam BCD2BIN_PIPE_STAGES = N_DIGITS;

// The number of digits for the smallest duplicate
// number is 2
localparam MIN_N_DIGITS = 2;
localparam MAX_N_DIGITS = N_DIGITS;
// Prime factors in the range of 20
parameter N_PRIME_FCTRS = 8;
localparam [N_PRIME_FCTRS-1:0][W_DIGITS-1:0] 
            PRIME_FCTRS = {
                W_DIGITS'(2), 
                W_DIGITS'(3), 
                W_DIGITS'(5), 
                W_DIGITS'(7), 
                W_DIGITS'(11), 
                W_DIGITS'(13),
                W_DIGITS'(17),
                W_DIGITS'(19)
            };

function automatic void clip_to_digit_range (
    input [W_DIGITS-1:0] i_digit,
    input [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] i_bcd_u,
    input [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] i_bcd_l,
    output [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] o_bcd_u,
    output [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] o_bcd_l
);
    logic [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] clip_max;
    logic [N_DIGITS-1:0][BIT_PER_DIGIT-1:0] clip_min;

    // Should be pregenerated, since they're constant
    clip_min = '0;
    clip_min[i_digit-1] = 4'd1;
    for (int i=0; i<N_DIGITS; i++) begin
        if (i < i_digit)
            clip_max[i] = 4'd9; 
    end

    o_bcd_u = i_bcd_u;
    o_bcd_l = i_bcd_l;
    // if the bcd range is out of clip bound
    // ignore the bcd range
    if (i_bcd_u < clip_min | i_bcd_l > clip_max) begin
        o_bcd_u = '0;
        o_bcd_l = '0;
    end
    else begin
        if (i_bcd_u > clip_max)
            o_bcd_u = clip_max; // clip at max
        if (i_bcd_l < clip_min)
            o_bcd_l = clip_min; // clip at min
    end
endfunction

endpackage
