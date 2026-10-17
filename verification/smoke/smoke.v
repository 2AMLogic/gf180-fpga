// Placeholder DUT for the harness smoke test: a 4-bit registered adder with
// synchronous reset. Not tile RTL; it only proves the harness can build,
// simulate and judge a design. Verilog-2005.
module smoke (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [4:0] sum
);
    always @(posedge clk) begin
        if (rst) sum <= 5'd0;
        else     sum <= {1'b0, a} + {1'b0, b};
    end
endmodule
