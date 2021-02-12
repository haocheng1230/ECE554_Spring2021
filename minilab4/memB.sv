module memB
    #(
    parameter BITS_AB=8,
    parameter DIM=8
    )
    (
    input clk, rst_n, en,
    input signed [BITS_AB-1:0] Bin [DIM-1:0],
    output signed [BITS_AB-1:0] Bout [DIM-1:0]
    );
    logic signed [BITS_AB-1:0] MACBdata[BITS_AB-1:0][BITS_AB-1:0];
    logic [$clog2(DIM)-1:0] count;
    genvar i;

    generate        
    for (i = 0; i < DIM ; i++) begin
        assign Bout[i] = MACBdata[i][0];
    end
    endgenerate 

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0 ; i < DIM ; i++) begin
                for (int j = 0 ; j < DIM ; j++) begin
                    MACBdata[i][j] <= 0;
                end
            end
            count <= 0;
        end else if (en) begin  
            for (int i = 0 ; i < DIM ; i++) begin
                for (int j = 0 ; j < DIM ; j++) begin
                    if (i == count) MACBdata[i][j] <= Bin[j];
                    else if (j == DIM-1) MACBdata[i][j] <= 0;
                    else MACBdata[i][j] <= MACBdata[i][j+1];
                end
            end
            count++;
        end
    end

endmodule