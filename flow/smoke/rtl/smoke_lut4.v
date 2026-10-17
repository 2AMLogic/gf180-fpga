// Flow smoke design, NOT the tile: a registered 4-input function.
module smoke_lut4 (
    input  wire       clk,
    input  wire [3:0] i,
    output reg        o
);
    // Arbitrary fixed 16-bit truth table.
    localparam [15:0] INIT = 16'h6996;
    always @(posedge clk) o <= INIT[i];
endmodule
