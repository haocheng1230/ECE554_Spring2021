// fifo.sv
// Implements delay buffer (fifo)
// On reset all entries are set to 0
// Shift causes fifo to shift out oldest entry to q, shift in d

module fifo
    #(
    parameter DEPTH=8,
    parameter BITS=64
    )
    (
    input clk,rst_n,en,
    input [BITS-1:0] d,
    output logic [BITS-1:0] q
    );
    logic [DEPTH-1:0][BITS-1:0] fifodatad, fifodataq;
    // logic [DEPTH-1:0] pivotaf, pivotb4;
    logic fifo_full, fifo_empty;
    mydff #(BITS) fifodata[DEPTH-1:0](.q(fifodataq), .d(fifodatad), .clk(clk), .rst_n(rst_n));
    // dff pivot(.q(pivotb4), .d(pivotaf), .clk(clk), .rst_n(rst_n));
    // defparam pivot.DFFBITS = DEPTH;
    // assign fifo_full = (pivotb4 == 8) ? 1 : 0;
    
    assign q = fifodataq[DEPTH-1];

    always_comb begin
        fifodatad = 0;
        case (en)
            1'b0: begin
                    for (int i = 0 ; i < DEPTH ; i++) begin
                    fifodatad[i] = fifodataq[i]; 
                    end
            end
            1'b1: begin // if enabled slide in and keep pivot
                fifodatad[0] = d;
                for (int i = 1 ; i < DEPTH ; i++) begin
                    fifodatad[i] = fifodataq[i-1];
                end
            end
        endcase
    end


endmodule // fifo