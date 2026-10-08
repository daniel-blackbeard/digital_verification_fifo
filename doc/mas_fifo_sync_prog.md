# MICROARCHITECTURE SPECIFICATION - FIFO_SYNC_PROG

## Introduction
This is a synchronous FIFO module, configurable via parameters, with programmable threshold indicators that anticipate the `empty` and `full` states. The thresholds are set through two words passed to this module. `DATA_WIDTH` (width of the read and write data) and `DEPTH` (number of elements in the FIFO, only powers of 2 are allowed) can be set to define the size of the FIFO. The default values are `DATA_WIDTH=8` and `DEPTH=16`. There is no real minimum `DEPTH`, but it is advised to be at least 4.

## Pin List
    input  logic                     clk                      Main clock
    input  logic                     rst                      Active high reset
    input  logic                     wr_en                    Write enable
    input  logic [DATA_WIDTH-1:0]    wr_data                  Write word into the FIFO
    input  logic                     rd_en                    Read enable
    output logic [DATA_WIDTH-1:0]    rd_data                  Read word out of the FIFO
    output logic                     empty                    Flag for empty FIFO
    output logic                     full                     Flag for full FIFO
    output logic                     almost_empty             Programmable flag for empty proximity
    output logic                     almost_full              Programmable flag for full proximity
    input  logic [clog2(DEPTH)-1:0]  almost_empty_tresh       Programming word for empty proximity
    input  logic [clog2(DEPTH)-1:0]  almost_full_tresh        Programming word for full proximity
    output logic [clog2(DEPTH):0]    count                    Monitor for the number of elements in the FIFO

## Functionality

### Clocking and reset
State transitions happen on the rising edge of the clock. Reset is asynchronous and active high. During reset the pointers and the counter are reset to zero. The internal FIFO memory is not reset, to allow for different implementations of it (the current implementation is plain registers, but BRAM is possible). This also means that `rd_data` is undefined while the FIFO is empty after reset. On reset the `empty` flag is asserted and the `full` flag is deasserted. The `almost_empty` and `almost_full` flags follow the programmed behavior and are asserted if their conditions are met.

### Flags behavior and timing
The flags are asserted and deasserted combinatorially. This means they change as soon as a read or write operation has completed, with at most a small delay due to wiring or buffering.

### Write into the FIFO
To write into the FIFO, `wr_en` and `wr_data` must be asserted with enough setup time before the rising clock edge. At the rising edge the data is sampled into the FIFO and the counter is increased by 1. When all the memory has been written, the FIFO asserts `full`. While `full` is asserted, any write request is silently ignored.

### Read from the FIFO
Reading from the FIFO is done by asserting `rd_en`. On the next rising edge of the clock, the front element of the queue is presented on `rd_data` and held until the next read. When all the written elements have been read out, the `empty` flag is asserted. In the `empty` state, any read request is silently ignored and `rd_data` keeps its previous value.

### Programmable thresholds
`almost_empty_tresh` and `almost_full_tresh` can be set combinatorially to any value (they have no impact on FIFO functionality). When the number of elements is less than or equal to `almost_empty_tresh`, the `almost_empty` flag is asserted. When the number of elements is greater than or equal to `almost_full_tresh`, the `almost_full` flag is asserted. They stay asserted when their corresponding `empty` and `full` flags are asserted.

### Read+Write behavior
In normal conditions a simultaneous read and write is not an issue: `count` stays the same, because one element is pushed and one is popped, so the FIFO size does not change. Two corner cases can occur:
  - R+W on empty: `empty` is an absolute flag and no read is allowed, hence only the write is executed.
  - R+W on full: `full` is an absolute flag and no write is allowed, hence only the read is executed.

### FIFO count
The `count` output keeps track of the number of elements queued in the FIFO. It can be used for any purpose, or left disconnected. When `full` is asserted it reports `DEPTH` elements.
