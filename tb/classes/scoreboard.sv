class scoreboard;

    mailbox #(result) mon_scr;
    mailbox #(result) ref_scr;
    int fail;
    int pass;

    function new(mailbox #(result) ms, mailbox #(result) rs);
        this.mon_scr = ms;
        this.ref_scr = rs;
        this.fail = 0;
        this.pass = 0;
    endfunction

    task run();
        result rxs;
        result rxr;

        forever begin
            mon_scr.get(rxs);
            ref_scr.get(rxr); 

            if(rxr.count == rxs.count) begin
            pass++;
            end else begin
                $display("FAIL - reference and dut count doesn't match (%d vs %d) - time %0.d", rxr.count, rxs.count, $time);
                fail++;
            end

            if(rxr.empty == rxs.empty) begin
            pass++;
            end else begin
                $display("FAIL - reference and dut empty doesn't match (%d vs %d) - time %0.d", rxr.empty, rxs.empty, $time);
                fail++;
            end

            if(rxr.full == rxs.full) begin
            pass++;
            end else begin
                $display("FAIL - reference and dut full doesn't match (%d vs %d) - time %0.d", rxr.full, rxs.full, $time);
                fail++;
            end

            if(rxr.almost_empty == rxs.almost_empty) begin
            pass++;
            end else begin
                $display("FAIL - reference and dut almost_empty doesn't match (%d vs %d) - time %0.d", rxr.almost_empty, rxs.almost_empty, $time);
                fail++;
            end

            if(rxr.almost_full == rxs.almost_full) begin
            pass++;
            end else begin
                $display("FAIL - reference and dut almost_full doesn't match (%d vs %d) - time %0.d", rxr.almost_full, rxs.almost_full, $time);
                fail++;
            end

            if(rxr.rd_data == rxs.rd_data) begin
            pass++;
            end else begin
                $display("FAIL - reference and dut rd_data doesn't match (%d vs %d) - time %0.d", rxr.rd_data, rxs.rd_data, $time);
                fail++;
            end
        end
    endtask

endclass
