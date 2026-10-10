# Digital verification training
This is a training project for self-teaching digital verification using systemverilog. For this the RTL and all the verification stages will be written by myself, while using Claude only as a tutor and to give a score/guidance on the learning path. 

For this training I will use Verilator and any other open source tool needed. No reliance of licensed tool.

The training is done in 5 stages:
# Stage 0 - Write the RTL
In this stage I write an RTL module only with the specifications. A documentation for the module is also provided
# Stage 1 - Simple assertions
Write a testbench with assertions (via bind) that check the behavior reported on the MAS, disregarding any knowledge on the RTL
# Stage 2 - Object-oriented systemVerilog testbench
A SV class framework that automatically generates stimulus, drives a reference model created from the understanding of the MAS and the actual RTL and makes comparisons between both block and gives back a score. This kind of testbench comes cleaner and it's capable of greater flexibility when it comes to tickling the corner cases.
# Stage 3 - Functional coverage
# Stage 4 - Formal methods