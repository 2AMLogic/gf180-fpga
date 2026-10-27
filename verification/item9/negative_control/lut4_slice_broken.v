// Deliberately broken copy of rtl/common/rtl/lut4_slice.v (negative control for
// verification/item9/benches.json). The output select is inverted: reg_sel=1
// selects the combinational LUT and reg_sel=0 the flip-flop. Every bench that
// exercises a slice must FAIL against this DUT. Never fix it.
`default_nettype none
`timescale 1ns/1ps

module lut4_slice (
    input  wire        clk,
    input  wire        rst,
    input  wire        ce,
    input  wire [3:0]  in,
    input  wire [15:0] lut_init,
    input  wire        reg_sel,
    output wire        out
);

    wire lut_out = lut_init[in];

    reg ff_q;
    always @(posedge clk) begin
        if (rst)
            ff_q <= 1'b0;
        else if (ce)
            ff_q <= lut_out;
    end

    assign out = reg_sel ? lut_out : ff_q;   // BROKEN: select inverted

endmodule

`default_nettype wire
