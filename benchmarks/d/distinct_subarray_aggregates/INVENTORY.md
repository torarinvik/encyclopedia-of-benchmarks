# Static inventory

Package: `distinct_subarray_aggregates`  
ABI: `i64_array_scalar`  
Exported symbol: `distinct_subarray_aggregates`  
Input: `[mode,N,values...]`, `0<=N<=64`, values in `0..255`.  
Modes: GCD, bitwise OR, bitwise AND; all use one suffix-range compression core.  
Maximum valid/parseable input lengths: 66/67 words.  
Result: `1024*aggregate_sum+suffix_distinct_count`, maximum `543130176`.  
Primary: contiguous range compression over equal suffix aggregates.  
Independent: direct O(N^2) folds and per-endpoint distinct sets.  
Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.  
Suite wiring: `benchmarks/run_i64_array_scalar.py` and
`benchmarks/verify_i64_array_scalar.py`.

The secondary packed field is bounded by 576, so multiplier 1024 is
collision-free. This is a static inventory; no programs, tests, checkers,
builds, compilers, benchmarks, scripts, or profilers were run.
