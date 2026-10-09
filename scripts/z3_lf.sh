#!/bin/sh
# Solver wrapper for Verilator constrained randomization (used by sim.ps1).
# The native Windows z3 ends its answers with CR LF; Verilator expects LF only.
z3 --in | sed -u 's/\r$//'
