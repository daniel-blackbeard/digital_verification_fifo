module tb_fifo_sync_prog;

// main clock
logic clk;
always #2 clk <= ~clk;

logic rst;
logic wr_en, rd_en;
logic [7:0] rd_data, wr_data;
logic empty, full, almost_empty, almost_full;
logic [3:0] almost_empty_tresh, almost_full_tresh;
logic [4:0] fifo_count;

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
    .count(fifo_count)
);

initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(1, tb_fifo_sync_prog);
    clk <= '0;
    rst <= '1;
    almost_empty_tresh <= 4'd3;
    almost_full_tresh  <= 4'd12;
    wr_data <= '0;
    wr_en <= '0;
    rd_en <= '0;
    #2
    #4
    rst <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd11;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd12;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd13;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd14;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd15;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd16;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd17;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd18;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd19;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd20;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd21;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd22;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd23;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd24;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd25;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    wr_data <= 8'd26;
    #4
    wr_en   <= '0;
    //======================
    #4
    wr_en   <= '1;
    rd_en   <= '1;
    #4
    wr_en   <= '0;
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

   //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    wr_en   <= '1;
    rd_en   <= '1;
    #4
    wr_en   <= '0;
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    #4
    rd_en   <= '0;

    //======================
    #4
    rd_en   <= '1;
    wr_en   <= '1;
    #4
    rd_en   <= '0;
    wr_en   <= '0;
    
    #4
    
    $display("Simulation completed, %0d failures", u_fifo.u_fifo_sva.fail);
    if(u_fifo.u_fifo_sva.fail == '0) $display("PASS"); else $display("FAIL");

    $finish();
    
end

endmodule
