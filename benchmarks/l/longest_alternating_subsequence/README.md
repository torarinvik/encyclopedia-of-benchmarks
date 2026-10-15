# Longest Alternating Subsequence

This benchmark follows the pinned [TheAlgorithms Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/LongestAlternatingSubsequence.java), which uses dynamic programming to find the longest strictly alternating subsequence. A subsequence may skip elements; adjacent selected values must alternate between `<` and `>`.

## Contract

- Input is an array of 0 through 512 signed 64-bit values, each constrained to Java's signed 32-bit integer range.
- Return the length of the longest strict alternating subsequence. Equal neighboring selected values do not count as a rise or fall.
- The pinned Java source initializes its result to 1, so its empty-array result is 1; the ports preserve this edge behavior. A singleton and an all-equal nonempty array also return 1.
- Return `-1` for an overlong array or a value outside the source's int32 domain.
- The source and ports use O(n²) dynamic programming with rising-ending and falling-ending states, using O(n) auxiliary storage.

## Workload and build

[`workload.json`](workload.json) covers the empty-source result, singleton/equal inputs, monotone and alternating arrays, duplicates, negative values, signed-int edges, and an out-of-domain value.

Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm longest_alternating_subsequence --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/l/longest_alternating_subsequence/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/longest_alternating_subsequence.c`](../../../c/l/longest_alternating_subsequence.c) |
| C3 | [`c3/l/longest_alternating_subsequence.c3`](../../../c3/l/longest_alternating_subsequence.c3) |
| C++ | [`cpp/l/longest_alternating_subsequence.cpp`](../../../cpp/l/longest_alternating_subsequence.cpp) |
| Elisa | [`elisa/l/longest_alternating_subsequence.elisa`](../../../elisa/l/longest_alternating_subsequence.elisa) |
| Nim | [`nim/l/longest_alternating_subsequence.nim`](../../../nim/l/longest_alternating_subsequence.nim) |
| Odin | [`odin/l/longest_alternating_subsequence.odin`](../../../odin/l/longest_alternating_subsequence.odin) |
| Rust | [`rust/l/longest_alternating_subsequence.rs`](../../../rust/l/longest_alternating_subsequence.rs) |
| V | [`v/l/longest_alternating_subsequence.v`](../../../v/l/longest_alternating_subsequence.v) |
| Zig | [`zig/l/longest_alternating_subsequence.zig`](../../../zig/l/longest_alternating_subsequence.zig) |

## TheAlgorithms reference

- [Java `LongestAlternatingSubsequence.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/LongestAlternatingSubsequence.java)
