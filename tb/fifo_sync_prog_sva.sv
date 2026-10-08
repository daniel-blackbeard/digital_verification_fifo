module fifo_sync_prog_sva#(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     wr_en,
    input  logic [DATA_WIDTH-1:0]    wr_data,
    input  logic                     rd_en,
    input  logic [DATA_WIDTH-1:0]    rd_data,
    input  logic                     empty,
    input  logic                     full,
    input  logic                     almost_empty,
    input  logic                     almost_full,
    input  logic [$clog2(DEPTH)-1:0] almost_empty_tresh,
    input  logic [$clog2(DEPTH)-1:0] almost_full_tresh,
    input  logic [$clog2(DEPTH):0]   count
);
/* verilator lint_off SYNCASYNCNET */
logic [31:0] fail;

property p_empty_on_reset;
    @(posedge clk) disable iff (~rst)
    1'b1 |-> empty == '1;
endproperty

property p_full_on_reset;
    @(posedge clk) disable iff (~rst)
    1'b1 |-> full == '0;
endproperty

property p_count_on_reset;
    @(posedge clk) disable iff (~rst)
    1'b1 |-> count == '0;
endproperty

property p_no_counter_inc_on_full;
    @(posedge clk) disable iff (rst)
    full |-> count == $bits(count)'(DEPTH);
endproperty

property p_no_counter_dec_on_empty;
    @(posedge clk) disable iff (rst)
    empty |-> count == $bits(count)'(0);
endproperty

property p_empty_full_neq;
    @(posedge clk) disable iff (rst)
    1'b1 |-> {empty, full} != 2'b11;
endproperty

property p_rw_same_clock;
    @(posedge clk) disable iff (rst)
    {rd_en, wr_en, empty, full} == 4'b1100 |=> $stable(count);
endproperty

property p_rw_same_clock_on_empty;
    @(posedge clk) disable iff (rst)
    {rd_en, wr_en, empty, full} == 4'b1110 |=> count == $bits(count)'(1);
endproperty

property p_rw_same_clock_on_full;
    @(posedge clk) disable iff (rst)
    {rd_en, wr_en, empty, full} == 4'b1101 |=> count == $bits(count)'(DEPTH-1);
endproperty

property p_almost_empty;
    @(posedge clk) disable iff (rst)
    count >= {1'b1, almost_empty_tresh} |-> almost_empty;
endproperty


property p_almost_full;
    @(posedge clk) disable iff (rst)
    count >= {1'b1, almost_full_tresh} |-> almost_full;
endproperty

property p_almost_empty_too;
    @(posedge clk) disable iff (rst)
    empty |-> almost_empty;
endproperty

property p_almost_full_too;
    @(posedge clk) disable iff (rst)
    full |-> almost_full;
endproperty

property p_read_on_empty;
    @(posedge clk) disable iff (rst)
    empty & rd_en |=> $stable(rd_data);
endproperty

assert property (p_no_counter_inc_on_full)  else begin $display("FAIL - FIFO count increased on full  (count = %d)           - time = %0t", count, $time); fail++; end
assert property (p_no_counter_dec_on_empty) else begin $display("FAIL - FIFO count decreased on empty (count = %d)           - time = %0t", count, $time); fail++; end
assert property (p_empty_full_neq)          else begin $display("FAIL - Empty and full both asserted                         - time = %0t", $time); fail++; end
assert property (p_empty_on_reset)          else begin $display("FAIL - Empty flag not asserted on reset                     - time = %0t", $time); fail++; end
assert property (p_full_on_reset)           else begin $display("FAIL - Full flag not asserted on reset                      - time = %0t", $time); fail++; end
assert property (p_count_on_reset)          else begin $display("FAIL - Count not zero on reset                              - time = %0t", $time); fail++; end
assert property (p_rw_same_clock)           else begin $display("FAIL - Count changed on concurrent RW (not full or empty)   - time = %0t", $time); fail++; end
assert property (p_rw_same_clock_on_empty)  else begin $display("FAIL - Count changed on concurrent RW on empty (count = %d) - time = %0t", count, $time); fail++; end
assert property (p_almost_empty)            else begin $display("FAIL - Almost empty not flagged                (count = %d) - time = %0t", count, $time); fail++; end
assert property (p_almost_full)             else begin $display("FAIL - Almost full not flagged                 (count = %d) - time = %0t", count, $time); fail++; end
assert property (p_almost_empty)            else begin $display("FAIL - Almost empty is not also empty when empty            - time = %0t", count, $time); fail++; end
assert property (p_almost_full)             else begin $display("FAIL - Almost full is not also full when full               - time = %0t", count, $time); fail++; end
assert property (p_read_on_empty)           else begin $display("FAIL - Read on empty changed rd_data                        - time = %0t", count, $time); fail++; end


/* verilator lint_on SYNCASYNCNET */
endmodule
