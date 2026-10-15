# Longest continuous increasing subsequence

This benchmark returns the length of the longest strictly increasing contiguous run in a signed integer array. Every adjacent value in the run must be greater than its predecessor; values cannot be skipped.

## Contract

- The input is a read-only array of signed 64-bit integers.
- Empty input returns `0`.
- Arrays with at most 10,000 values in `[-1,000,000, 1,000,000]` return the longest strictly increasing contiguous run length.
- An array longer than 10,000 values, or containing a value outside the permitted range, returns `-1`.
- The reference implementation scans adjacent values and resets the current run whenever the sequence stops increasing.

## Upstream review

The C candidate `674.c` implements this contiguous-run scan for LeetCode 674. This benchmark fixes the behavior into a portable ABI contract and makes the supported length and value bounds explicit. Source: [TheAlgorithms/C, 674.c](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/674.c).

## Implementations

Portable implementations use the same C ABI in `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`. Each validates the array bounds and scans once, using constant extra space.

## Workload and verification

`workload.json` covers empty and singleton inputs, increasing and decreasing runs, equal values, negative values, ties and signed-range boundaries, maximum-length arrays, and invalid bounds. `benchmarks/verify_longest_continuous_increasing_subsequence.py` checks exhaustive short arrays, deterministic random arrays, boundary arrays, and every published workload case across all nine languages.

Build and record with the `i64_array_scalar` ABI family and `benchmarks/run_i64_array_scalar.py`.
