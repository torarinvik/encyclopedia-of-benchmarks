# Fannkuch prefix-reversal maximum

This package ports the algorithm in [`lac-dcc/Benchmarks/BenchmarkGame/fannkuch/fannkuch.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/fannkuch/fannkuch.c), attributed there to Heiner Marxen. The port preserves its counter-driven permutation traversal and optimized prefix-reversal loop, and returns the maximum number of flips observed. The source's printed permutation rows are omitted because this suite uses a scalar-return ABI.

The input is a single integer `n` in `[1, 8]`. The upstream program defaults to `n=11`; this bounded workload caps `n` at 8 to keep the full `n!` traversal practical. The result is the source algorithm's maximum prefix-reversal count, not an official Benchmark Game score. Internal permutations remain zero-based as in the C source; the upstream display adds one only when printing them.

The referenced C file carries no explicit license notice. This repository's implementations are independently written ports, with attribution and source reference recorded in `workload.json`; no upstream source blocks are copied.

Malformed framing, values outside the bound, or trailing input return `-1`.
