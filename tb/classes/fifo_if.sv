interface fifo_if #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic clk,
    input  logic rst
);
  
logic                     wr_en;
logic [DATA_WIDTH-1:0]    wr_data;
logic                     rd_en;
logic [DATA_WIDTH-1:0]    rd_data;
logic                     empty;
logic                     full;
logic                     almost_empty;
logic                     almost_full;
logic [$clog2(DEPTH)-1:0] almost_empty_tresh;
logic [$clog2(DEPTH)-1:0] almost_full_tresh;
logic [$clog2(DEPTH):0]   count;

clocking cb @(posedge clk);
    default input #1step output #1ps;
    input  rd_data;
    input  empty;
    input  full;
    input  almost_empty;
    input  almost_full;
    input  count;
    output rd_en;
    output wr_en;
    output wr_data;
    output almost_empty_tresh;
    output almost_full_tresh;
endclocking

clocking cbm @(posedge clk);
    default input #1step output #1ps;
    input  rd_data;
    input  empty;
    input  full;
    input  almost_empty;
    input  almost_full;
    input  count;
    input  rd_en;
    input  wr_en;
    input  wr_data;
    input  almost_empty_tresh;
    input  almost_full_tresh;
endclocking

endinterface
