module rrb_fv_tb #(parameter int N= 4) (
    input logic [N-1:0] req,
    input logic [N-1:0] gnt,

    input logic clk, rst
);

logic [1:0] symb_req, symb_req1, symb_req2;

assume property ( @(posedge clk) disable iff(rst) $stable(symb_req) );

//assume request stays untils gets granted
assume property (@(posedge clk) disable iff(rst) req[symb_req] && !gnt[symb_req] |-> req[symb_req] s_until_with gnt[symb_req]);

//other ways on request stays until gets granted
//assume property (@(posedge clk) disable iff(rst) req[symb_req] && !gnt[symb_req] |=> req[symb_req]);




//after reset, no one is granted
assert property ( @(posedge clk) $rose(rst) |-> gnt = 4'b0000 );

//request gets eventually granted
assert property ( @(posedge clk) disable iff (rst) req[symb_req] |-> s_eventually gnt[symb_req]);

//atmost one gnt at a time
assert property ( @(posedge clk) disable iff(rst) $onehot0(gnt));

//gnt occurs only when req is active
assert property ( @(posedge clk) disable iff(rst) gnt[symb_req] |-> req[symb_req] );

//no request means no gnt
assert property ( @(posedge clk) disable iff(rst) !(|req) |-> !(|gnt) );

//assume symb_reqs are stablke and not equal
assume property ( @(posedge clk) disable iff(rst) $stable(symb_req1) && $stable(symb_req2) && (symb_req1 != symb_req2) );

// logic req_to_be_gntd;

// always_ff @( posedge clk) begin
//     if(rst) begin
//         req_to_be_gntd <= 1'b0;
//     end else if( req[symb_req1] && req[symb_req2] && gnt[symb_req1]) req_to_be_gntd <= 1'b1;
//     else if (gnt[symb_req2]) req_to_be_gntd <= 1'b0;
// end

// assert property ( @(posedge clk) disable iff(rst) gnt[symb_req1] |-> !req_to_be_gntd);

assert property ( @(posedge clk) disable iff(rst) req[symb_req1] && req[symb_req2] && gnt[symb_req1] |=> !gnt[symb_req1] s_until_with gnt[symb_req2]);

assert property ( @(posedge clk) disable iff(rst) (|req) |-> (|gnt) );



//cover properties

//simultaneous reqs occur
cover property ( @(posedge clk) disable iff(rst) $countones(req) > 1);

//back-to-back gnt to different reqs
cover property ( @(posedge clk) disable iff(rst) gnt[0] ##1 gnt[1] ##1 gnt[2] ##1 gnt[3] );

endmodule
