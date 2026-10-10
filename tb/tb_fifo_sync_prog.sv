module tb_fifo_sync_prog;

// main clock
logic clk;
always #2 clk <= ~clk;

logic rst;
environment env;

fifo_if phy_if(.clk(clk), .rst(rst));

bind fifo_sync_prog fifo_sync_prog_sva u_fifo_sva(
    .clk(clk),
    .rst(rst),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .rd_en(rd_en),
    .rd_data(rd_data),
    .empty(empty),
    .full(full),
    .almost_empty(almost_empty),
    .almost_full(almost_full),
    .almost_empty_tresh(almost_empty_tresh),
    .almost_full_tresh(almost_full_tresh),
    .count(count)
);

fifo_sync_prog u_fifo(
    .clk(clk),
    .rst(rst),
    .wr_en(phy_if.wr_en),
    .wr_data(phy_if.wr_data),
    .rd_en(phy_if.rd_en),
    .rd_data(phy_if.rd_data),
    .empty(phy_if.empty),
    .full(phy_if.full),
    .almost_empty(phy_if.almost_empty),
    .almost_full(phy_if.almost_full),
    .almost_empty_tresh(phy_if.almost_empty_tresh),
    .almost_full_tresh(phy_if.almost_full_tresh),
    .count(phy_if.count)
);

initial begin
    env = new(phy_if);
    $dumpfile("waveform.vcd");
    $dumpvars(1, tb_fifo_sync_prog);

    rst <= '1;
    #8
    rst <= '0;

    env.setup();
    for(int n=0; n<8; n++) begin
        env.gen.fill_fifo();
        env.gen.run(32);
        env.gen.empty_fifo();
        env.gen.run(32);
    end
    env.wait_until_done();
    env.report_results();

    $display("Simulation completed, %0d failures from SVA", u_fifo.u_fifo_sva.fail);
    if(u_fifo.u_fifo_sva.fail == '0) $display("PASS\n"); else $display("FAIL\n");

end

endmodule
