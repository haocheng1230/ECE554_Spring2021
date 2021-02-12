module mydff 
    #(
    parameter DFFBITS=64
    ) (
    output logic [DFFBITS-1:0] q, 
    input logic [DFFBITS-1:0] d, 
    input wire clk,
    input wire rst_n);

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) q <= 0;
        else q <= d;
    end

endmodule
// DUMMY LINE FOR REV CONTROL :0:
