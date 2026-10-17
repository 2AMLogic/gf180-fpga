// Deliberately broken twin of smoke.v: the carry bit is dropped, so any
// a + b >= 16 is wrong. test_smoke.py MUST fail against this file; if it
// does not, the harness cannot detect a bad DUT. Never "fix" this file.
module smoke (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [4:0] sum
);
    always @(posedge clk) begin
        if (rst) sum <= 5'd0;
        else     sum <= {1'b0, a + b};
    end
endmodule
