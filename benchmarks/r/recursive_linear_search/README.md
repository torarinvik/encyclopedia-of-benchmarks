# Recursive linear search

Search a bounded integer array recursively and return the zero-based index of a match, or `-1` when the target is absent.

## Contract

- The `i64_array_scalar` input is `[n, target, value_0, ..., value_(n-1)]`.
- `n` is 1 through 64. The target and values are signed integers in `[-1,000,000, 1,000,000]`.
- Values must be distinct. This precondition makes the Fortran source's backward recursive scan and the Ruby source's two-ended inward recursion return the same matching index. Duplicate-containing inputs are outside the benchmark domain.
- A valid call returns the zero-based array index containing the target, or `-1` when absent. A malformed packed length or count outside the bound returns `-1`.
- The Fortran source returns one-based positions; the benchmark adapter subtracts one for found values. The Ruby source already returns zero-based positions.
- The ported recursion walks from the last element toward the first. The 64-element cap limits call depth and keeps this bounded search safe for the nine target runtimes.
- The parser accepts 67 values: the largest valid row is 66 values, so one extra element can reach the ABI as a malformed row.

## Workload and oracle

[`workload.json`](workload.json) includes the pinned examples, first/middle/last hits, a miss, one-element and 64-element arrays, and malformed lengths/counts. The independent oracle is [`recursive_linear_search_oracle.py`](../../recursive_linear_search_oracle.py).

## Pinned sources

- [TheAlgorithms/Fortran `recursive_linear_search.f90`](https://github.com/TheAlgorithms/Fortran/blob/c91199703b78bd2181051b01bd5269740e41e121/modules/searches/recursive_linear_search.f90)
- [TheAlgorithms/Ruby `recursive_linear_search.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/searches/recursive_linear_search.rb)

## Build and record

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm recursive_linear_search --language rust
    python3 benchmarks/run_i64_array_scalar.py --algorithm recursive_linear_search
    python3 benchmarks/verify_i64_array_scalar.py --algorithms recursive_linear_search

All nine ports passed 164 oracle arrays each and recorded all 16 workload cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/recursive_linear_search.c`](../../../c/r/recursive_linear_search.c) |
| C3 | [`c3/r/recursive_linear_search.c3`](../../../c3/r/recursive_linear_search.c3) |
| C++ | [`cpp/r/recursive_linear_search.cpp`](../../../cpp/r/recursive_linear_search.cpp) |
| Elisa | [`elisa/r/recursive_linear_search.elisa`](../../../elisa/r/recursive_linear_search.elisa) |
| Nim | [`nim/r/recursive_linear_search.nim`](../../../nim/r/recursive_linear_search.nim) |
| Odin | [`odin/r/recursive_linear_search.odin`](../../../odin/r/recursive_linear_search.odin) |
| Rust | [`rust/r/recursive_linear_search.rs`](../../../rust/r/recursive_linear_search.rs) |
| V | [`v/r/recursive_linear_search.v`](../../../v/r/recursive_linear_search.v) |
| Zig | [`zig/r/recursive_linear_search.zig`](../../../zig/r/recursive_linear_search.zig) |
