/*
module round_robin_arbiter #( parameter int N = 4) (
    input logic [N-1:0] req,
    input logic clk, rst,

    output logic [N-1:0] gnt
);

logic [N-1:0] req_shifted, gnt_shifted;

logic [$clog2(N)-1:0] cnt;

always_comb begin //shift right by cnt
    case(cnt)
        0: req_shifted = req;
        1: req_shifted = {req[0], req[N-1:1]};
        2: req_shifted = {req[N-3:0], req[N-1:N-2]};
        3: req_shifted = {req[N-2:0], req[N-1]};
    endcase
end

assign gnt_shifted = req_shifted & (-req_shifted); //gets the rightmost/highest priorty gnt

always_comb begin //shift back left by cnt
    if(rst) gnt ='0;
    else begin
        case(cnt)
            0: gnt = gnt_shifted;
            1: gnt = {gnt_shifted[N-2:0], gnt_shifted[N-1]};
            2: gnt = {gnt_shifted[N-3:0], gnt_shifted[N-1:N-2]};
            3: gnt = {gnt_shifted[0], gnt_shifted[N-1:N-3]};
        endcase
    end
end


always_ff @(posedge clk) begin
    if(rst) cnt <= '0;
    else if(|gnt) begin
        case(gnt)
            4'b0001: cnt <= 1;
            4'b0010: cnt <= 2;
            4'b0100: cnt <= 3;
            4'b1000: cnt <= 0;
        endcase
    end
end

endmodule
*/


module rrarb_p #(parameter int N = 4) (
    input logic [N-1:0] req,
    input logic clk, rst,

    output logic [N-1:0] gnt
);

logic [N-1:0] req_shift, gnt_shift;
logic [$clog2(N)-1:0] cnt;

always_comb begin
    if(cnt == 0) req_shift = req;
    else begin
        //shift right by count time and or it with shift left by difference of Max count and count present
        req_shift = (req >> cnt) | (req << (N - cnt));
    end
end

//for nt_shift we need LSB 1 and rest 0, do previous substraction trick
assign gnt_shift = req_shift & (-req_shift);

always_comb begin
    if(cnt == 0) gnt = gnt_shift;
    else begin
        //shift back left by count time and or it with shift right by difference of Max count and count present
        gnt = (gnt_shift << cnt) | (gnt_shift >> (N - cnt));
    end
end

always_ff @(posedge clk) begin
    if(rst) cnt <= '0;
    else if(|gnt) begin
        for(int i = 0; i<N; i++) begin
            if(gnt[i]) begin
                cnt <= (i == N-1)? '0 : i+1;
            end
        end
    end
end
endmodule
