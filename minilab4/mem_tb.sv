module mem_tb();
    localparam BITS_AB = 8;
    localparam BITS_C = 16;
    localparam DIM = 8;
    localparam ROWBITS = $clog2(DIM);
    
    logic clk, rst_n, WrEn, enA, enB;
    logic signed [BITS_AB-1:0] Ain [DIM-1:0], Bin [DIM-1:0];
    logic [$clog2(DIM)-1:0] Arow;
    logic signed [BITS_AB-1:0] Aout [DIM-1:0], Bout [DIM-1:0];

    logic signed [BITS_AB-1:0] memAData [DIM-1:0][DIM*2-1:0], memBData [DIM*2-1:0][DIM-1:0];
    initial clk = 0;
    always #5 clk = ~clk;
    logic [2:0] seq [7:0] = {4,5,3,0,2,1,7,6};
        
    memA memADUT
    (
    .clk(clk), .rst_n(rst_n), .WrEn(WrEn), .en(enA),
    .Ain(Ain), .Arow(Arow), .Aout(Aout)
    );

    memB memBDUT
    (
    .clk(clk), .rst_n(rst_n), .en(enB),
    .Bin(Bin), .Bout(Bout)
    );

    initial begin
        automatic int errcA = 0;
        automatic int errcB = 0;
        WrEn = 0;
        enA = 0;
        enB = 0;
        rst_n = 0;
        repeat (2) @(posedge clk);
        rst_n = 1; // reset

        for (int i = 0 ; i < DIM ; i++) begin
            for (int j = 0 ; j < DIM*2 ; j++) begin
                if (j > DIM-1-i && j <= DIM*2-1-i) memAData[seq[i]][j] = $urandom;
                else memAData[seq[i]][j] = 0;
            end
        end

        for (int j = 0 ; j < DIM ; j++) begin
            for (int i = 0 ; i < DIM*2 ; i++) begin
                if (i > DIM-1-j && i <= DIM*2-1-j) memBData[i][j] = $urandom;
                else memBData[i][j] = 0;
            end
        end // data setup for normal function test

        WrEn = 1;
        for (int i = 0 ; i < DIM*3-2 ; i++) begin
            automatic int errtemp = 0;
            automatic string actual = "";
            automatic string expected = "";
            if (i == 8) begin
                WrEn = 0;
                enA = 1;
            end
            if (i > 0 && i < 17) begin // only check tables for 16 cycles
                for (int j = 0 ; j < DIM ; j++) begin
                    if (Aout[j] != memAData[j][DIM*2-i+1]) begin
                        errtemp++;
                    end
                    actual = {actual,$sformatf("%h",Aout[j]),","};
                    expected = {expected,$sformatf("%h",memAData[j][DIM*2-i+1]),","};
                end

                if (errtemp != 0) begin
                    $display("ERROR: At %d cycle | Expected Aout: %s | Actual Aout: %s", i, expected, actual);
                    errcA++;
                end
            end else begin
                for (int j = 0 ; j < DIM ; j++) begin
                    if (Aout[j] != 0) begin
                        $display("ERROR: At %d cycle all output are expected to be 0, but it is not!", i);
                        errcA++;
                    end
                end
            end // check output matches

            if (i < 8) begin // only write values for 8 cycles
                Arow = seq[i];
                for (int j = 0 ; j < DIM ; j++) begin
                    Ain[j] = memAData[seq[i]][DIM*2-1-i-j];
                end
            end else begin // write new values to A
                for (int j = 0 ; j < DIM ; j++) begin
                    Ain[j] = 0;
                end
            end
            @(posedge clk);
        end
        enA = 0;

        $display("-------------------------------------");
        $display("Below is memAData");
        for (int i = 0 ; i < DIM ; i++) begin
            for (int j = 0 ; j < DIM*2 ; j++) begin
                    $write("%h,", memAData[i][j]);
            end
            $write("\n");
        end
        if (errcA > 0) begin
            $display("memA TEST FAILED! CHECK ERROR LOG");
            $display("Total error: %d", errcA);
        end else begin
            $display("memA TEST PASSED!");
        end

        enB = 1;
        for (int i = 0 ; i < DIM*3-2 ; i++) begin
            automatic int errtemp = 0;
            automatic string actual = "";
            automatic string expected = "";
            if (i > 0 && i < 17) begin // only check tables for 16 cycles
                for (int j = 0 ; j < DIM ; j++) begin
                    if (Bout[j] != memBData[DIM*2-i+1][j]) begin
                        errtemp++;
                    end
                    actual = {actual,$sformatf("%h",Bout[j]),","};
                    expected = {expected,$sformatf("%h",memBData[DIM*2-i+1][j]),","};
                end

                if (errtemp != 0) begin
                    $display("ERROR: At %d cycle | Expected Bout: %s | Actual Bout: %s", i, expected, actual);
                    errcB++;
                end
            end else begin
                for (int j = 0 ; j < DIM ; j++) begin
                    if (Bout[j] != 0) begin
                        $display("ERROR: At %d cycle all output are expected to be 0, but it is not!", i);
                        errcB++;
                    end
                end
            end // check output matches
            if (i < 8) begin // only write values for 8 cycles
                for (int j = 0 ; j < DIM ; j++) begin
                    Bin[j] = memBData[DIM*2-1-i-j][i];
                end
            end else begin // write new values to B
                for (int j = 0 ; j < DIM ; j++) begin
                    Bin[j] = 0;
                end
            end
            @(posedge clk);
        end
        enB = 0;

        $display("-------------------------------------");
        $display("Below is memBData");
        for (int i = 0 ; i < DIM*2 ; i++) begin
            for (int j = 0 ; j < DIM ; j++) begin
                    $write("%h,", memBData[i][j]);
            end
            $write("\n");
        end
        if (errcB > 0) begin
            $display("memB TEST FAILED! CHECK ERROR LOG");
            $display("Total error: %d", errcB);
        end else begin
            $display("memB TEST PASSED!");
        end
        
        $stop;
    end

endmodule

/*
enA = 1;
        for (int i = 0 ; i < DIM*3-2 ; i++) begin
            automatic int errtemp = 0;
            automatic string actual = "";
            automatic string expected = "";
            if (i > 0 && i < 17) begin // only check tables for 16 cycles
                for (int j = 0 ; j < DIM ; j++) begin
                    if (Aout[j] != memAData[j][DIM*2-i+1]) begin
                        errtemp++;
                    end
                    actual = {actual,$sformatf("%h",Aout[j]),","};
                    expected = {expected,$sformatf("%h",memAData[j][DIM*2-i+1]),","};
                end

                if (errtemp != 0) begin
                    $display("ERROR: At %d cycle | Expected Aout: %s | Actual Aout: %s", i, expected, actual);
                end
            end else begin
                for (int j = 0 ; j < DIM ; j++) begin
                    if (Aout[j] != 0) begin
                        $display("ERROR: At %d cycle all output are expected to be 0, but it is not!", i);
                    end
                end
            end // check output matches
            if (i < 8) begin // only write values for 8 cycles
                for (int j = 0 ; j < DIM ; j++) begin
                    Ain[j] = memAData[i][DIM*2-1-i-j];
                    // Bin[j] = memBData[DIM-i+j][i];
                end
            end else begin // write new values to A
                for (int j = 0 ; j < DIM ; j++) begin
                    Ain[j] = 0;
                    // Bin[j] = memBData[DIM-i+j][i];
                end
            end
            @(posedge clk);
        end
        enA = 0;

        // enB = 1;
        // for (int i = 0 ; i < DIM*3-2 ; i++) begin
        //     if (i > 0 && i < 17) begin // only check tables for 16 cycles
        //         var automatic errtemp = 0;
        //         var automatic actual = "";
        //         var automatic expected = "";
        //         for (int j = 0 ; j < DIM ; j++) begin
        //             if (Bout[j] != memBData[16-i][j]) begin
        //                 errtemp++;
        //             end
        //             actual = {actual,Bout[j],","};
        //             expected = {expected,memBData[16-i][j],","};
        //         end

        //         if (errtemp != 0) begin
        //             $display("ERROR: At %d cycle | Expected Bout: %s | Actual Bout: %s", i, expected, actual);
        //         end
        //     end else begin
        //         for (int j = 0 ; j < DIM ; j++) begin
        //             if (Bout[j] != 0) begin
        //                 $display("ERROR: At %d cycle all output are expected to be 0, but it is not!", i);
        //             end
        //         end
        //     end // check output matches
        //     if (i < 8) begin // only write values for 8 cycles
        //         for (int j = 0 ; j < DIM ; j++) begin
        //             // Ain[j] = memAData[i][DIM-i+j];
        //             Bin[j] = memBData[DIM-i+j][i];
        //         end
        //     end // write new values to A
        //     @(posedge clk);
        // end
        // enB = 0;

        // $display("-------------------------------------");
        // $display("Below is memBData");
        // for (int i = 0 ; i < DIM*2 ; i++) begin
        //     for (int j = 0 ; j < DIM ; j++) begin
        //             $write("%h,", memBData[i][j]);
        //     end
        //     $write("\n");
        // end
*/
