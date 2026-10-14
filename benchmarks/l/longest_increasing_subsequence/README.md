# Longest increasing subsequence

This benchmark returns the length of the longest strictly increasing subsequence of a signed 64-bit integer array. A subsequence may skip elements; it does not need to be contiguous.

## Contract

- The input is a read-only array of signed 64-bit integers.
- Empty input returns `0`.
- Inputs of up to 512 values return the length of a strictly increasing subsequence. Equal values do not extend a subsequence.
- Inputs longer than 512 values return `-1`.
- The reference implementation uses quadratic dynamic programming: for each index, it stores the longest increasing subsequence ending there and extends only from earlier, strictly smaller values.

The local implementation is O(n²), using a fixed 512-element scratch array. The independent verifier uses a binary-search tails oracle, which checks the same strict semantics through a different algorithm.

## Upstream review

The pinned C++ dynamic-programming, Java binary-search, Rust, and Zig sources implement strict increasing subsequences. The Python file with the canonical filename uses `>=`, so equal values can extend its result; it is documented here as a non-decreasing variant rather than treated as an exact strict-LIS port. The separately named Python iterative version uses `<=`, and C's generic `longest_subsequence` also permits equal values. Those variants are not aliases of this strict contract.

The strict O(n log n) variants in Java, C++, Python, and Go share the strict contract and are recorded as aliases below. Source references: [C++ dynamic programming](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/longest_increasing_subsequence.cpp), [Java dynamic programming](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/LongestIncreasingSubsequence.java), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/longest_increasing_subsequence.rs), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dynamicProgramming/longestIncreasingSubsequence.zig).

## Implementations

Portable implementations use the same C ABI in `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`. Elisa expresses the nested dynamic-programming loops as values and carries the mutable DP state through those loop expressions.

## Workload and verification

`workload.json` covers empty and singleton inputs, non-contiguous subsequences, increasing and decreasing arrays, duplicates, negative values, signed 64-bit boundaries, the maximum supported length, and the first rejected length. `benchmarks/verify_longest_increasing_subsequence.py` checks exhaustive short arrays, deterministic random arrays, boundary values, and every published workload case in all nine languages.

Build and record with the `i64_array_scalar` ABI family and `benchmarks/run_i64_array_scalar.py`.
