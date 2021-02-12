module tpumac_tb ();
    parameter BITS_AB = 8;
    parameter BITS_C = 16;

    logic clk, rst_n, WrEn, en;
    logic signed [BITS_AB-1:0] Ain[BITS_AB-1:0][BITS_AB-1:0], Bin[BITS_AB-1:0][BITS_AB-1:0],
    Aout[BITS_AB-1:0][BITS_AB-1:0], Bout[BITS_AB-1:0][BITS_AB-1:0];
    logic signed [BITS_C-1:0] Cin[BITS_AB-1:0][BITS_AB-1:0], Cout[BITS_AB-1:0][BITS_AB-1:0];
    logic signed [BITS_C-1:0] Cexp[BITS_C-1:0][BITS_C-1:0];
    logic signed [BITS_AB-1:0] Adata[BITS_AB-1:0][BITS_AB-1:0], Bdata[BITS_AB-1:0][BITS_AB-1:0];
    logic signed [BITS_C-1:0] Cdata[BITS_AB-1:0][BITS_AB-1:0];
    logic signed [BITS_AB-1:0] tempA[BITS_AB-1:0][BITS_AB-1:0], tempB[BITS_AB-1:0][BITS_AB-1:0];

    tpumac iDUT[BITS_AB-1:0][BITS_AB-1:0] (
    .clk(clk), .rst_n(rst_n), .WrEn(WrEn), .en(en),
    .Ain(Ain), .Bin(Bin), .Cin(Cin),
    .Aout(Aout), .Bout(Bout), .Cout(Cout)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        for (int i = 0 ; i < BITS_AB ; i++) begin
            for (int j = 0 ; j < BITS_AB ; j++) begin
                Cdata[i][j] = $urandom;
            end
        end // fill an array of 8x8 with random number
        testWrEn(Cdata, "WrEn");

        for (int i = 0 ; i < BITS_AB ; i++) begin
            for (int j = 0 ; j < BITS_AB ; j++) begin
                tempA[i][j] = 1;
                tempB[i][j] = 1;
            end
        end // fill an array of 8x8 with 1
        testwithinputs(tempA, tempB, "SIMPLE");

        for (int i = 0 ; i < BITS_AB ; i++) begin
            for (int j = 0 ; j < BITS_AB ; j++) begin
                tempA[i][j] = $urandom;
                tempB[i][j] = $urandom;
            end
        end // fill an array of 8x8 with random number
        testwithinputs(tempA, tempB, "RANDOM");
        
        $stop;

    end

    task testwithinputs(input logic signed [BITS_AB-1:0] A [BITS_AB-1:0][BITS_AB-1:0],
    input logic signed [BITS_AB-1:0] B [BITS_AB-1:0][BITS_AB-1:0], input string name);
    begin
        var automatic errc = 0;

        rst_n = 0;
        repeat (2) @(posedge clk);
        rst_n = 1; // reset

        for (int i = 0 ; i < BITS_AB ; i++) begin
            for (int j = 0 ; j < BITS_AB ; j++) begin
                Adata[i][j] = A[i][j];
                Bdata[i][j] = B[i][j];
                Ain[i][j] = 0;
                Bin[i][j] = 0;
                Cin[i][j] = 0;
                Cexp[i][j] = 0;
            end
        end // input data and initialize array
        WrEn = 0;
        en = 1;
        for (int k = 0 ; k < BITS_AB ; k++) begin
            for (int i = 0 ; i < BITS_AB ; i++) begin
                for (int j = 0 ; j < BITS_AB ; j++) begin
                        Ain[i][j] = Adata[i][k];
                        Bin[i][j] = Bdata[k][j];
                        Cexp[i][j] += Adata[i][k]*Bdata[k][j];
                end
            end
            @(posedge clk);
        end
        en = 0;
        // apply data to tpumac and apply waittime for calculation to complete
        repeat (2) @(posedge clk);
        // here we are implicitly testing if Cout will hold when en = 0 by waiting one extra clk cycle
        $display("-------------------------------------");
        $display("Below is Adata");
        for (int i = 0 ; i < BITS_AB ; i++) begin
            for (int j = 0 ; j < BITS_AB ; j++) begin
                    $write("%h,", Adata[i][j]);
            end
            $write("\n");
        end
        $display("-------------------------------------");
        $display("Below is Bdata");
        for (int i = 0 ; i < BITS_AB ; i++) begin
            for (int j = 0 ; j < BITS_AB ; j++) begin
                    $write("%h,", Bdata[i][j]);
            end
            $write("\n");
        end
        $display("-------------------------------------");
        $display("Below is the expected result");
        for (int i = 0 ; i < BITS_AB ; i++) begin
            for (int j = 0 ; j < BITS_AB ; j++) begin
                    $write("%h,", Cexp[i][j]);
            end
            $write("\n");
        end
        $display("-------------------------------------");
        for (int i = 0 ; i < BITS_AB ; i++) begin
            for (int j = 0 ; j < BITS_AB ; j++) begin
                if (Cexp[i][j] != Cout[i][j]) begin
                    errc++;
                    $display("ERROR: At [%d,%d] | Expected: %h | Result: %h", i, j, Cexp[i][j], Cout[i][j]);
                end
            end
        end
        $display("-------------------------------------");

        if (errc > 0) begin
            $display("%s TEST FAILED! CHECK ERROR LOG", name);
            $display("Total error: %d", errc);
        end else begin
            $display("%s TEST PASSED!", name);
        end
    end
    endtask

    task testWrEn(input logic signed [BITS_C-1:0] C [BITS_AB-1:0][BITS_AB-1:0], input string name);
    begin
        var automatic errc = 0;

        for (int i = 0 ; i < BITS_AB ; i++) begin
            for (int j = 0 ; j < BITS_AB ; j++) begin
                Ain[i][j] = 0;
                Bin[i][j] = 0;
                Cin[i][j] = C[i][j];
                Cexp[i][j] = 0;
            end
        end // input data and initialize array

        en = 1;
        WrEn = 1;
        @(posedge clk);
        en = 0;
        WrEn = 0;
        // wait for data to be processed by module

        for (int i = 0 ; i < BITS_AB ; i++) begin
            for (int j = 0 ; j < BITS_AB ; j++) begin
                if (C[i][j] != Cout[i][j]) begin
                    errc++;
                    $display("ERROR: At [%d,%d] | Expected: %h | Result: %h", i, j, Cexp[i][j], Cout[i][j]);
                end
            end
        end
        $display("-------------------------------------");

        if (errc > 0) begin
            $display("%s TEST FAILED! CHECK ERROR LOG", name);
            $display("Total error: %d", errc);
        end else begin
            $display("%s TEST PASSED!", name);
        end

    end
    endtask //
endmodule