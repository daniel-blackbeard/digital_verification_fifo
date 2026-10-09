class scoreboard;

    mailbox #(result) mon_scr;
    mailbox #(result) ref_scr;
    int fail;

    function new(mailbox #(result) ms, mailbox #(result) rs);
        this.mon_scr = ms;
        this.ref_scr = rs;
        this.fail = 0;
    endfunction

    task run();
        result rxs;
        result rxr;

        forever begin
            mon_scr.get(rxs);
            ref_scr.get(rxr); 

            if(rxr.count == rxs.count) begin
                ;
            end else begin
                $display("FAIL - reference and dut count doesn't match (%d vs %d)", rxr.count, rxs.count);
                fail++;
            end

            if(rxr.empty == rxs.empty) begin
                ;
            end else begin
                $display("FAIL - reference and dut empty doesn't match (%d vs %d)", rxr.empty, rxs.empty);
                fail++;
            end

            if(rxr.full == rxs.full) begin
                ;
            end else begin
                $display("FAIL - reference and dut full doesn't match (%d vs %d)", rxr.full, rxs.full);
                fail++;
            end

            if(rxr.almost_empty == rxs.almost_empty) begin
                ;
            end else begin
                $display("FAIL - reference and dut almost_empty doesn't match (%d vs %d)", rxr.almost_empty, rxs.almost_empty);
                fail++;
            end

            if(rxr.almost_full == rxs.almost_full) begin
                ;
            end else begin
                $display("FAIL - reference and dut almost_full doesn't match (%d vs %d)", rxr.almost_full, rxs.almost_full);
                fail++;
            end

            if(rxr.rd_data == rxs.rd_data) begin
                ;
            end else begin
                $display("FAIL - reference and dut rd_data doesn't match (%d vs %d)", rxr.rd_data, rxs.rd_data);
                fail++;
            end
        end
    endtask

endclass
