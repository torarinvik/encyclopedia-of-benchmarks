# Interquartile Range

This package ports the lower/upper-half interquartile range calculation from the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/interquartile_range.py) and [TheAlgorithms/Rust implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/interquartile_range.rs). Both sort the input, split it into lower and upper halves, compute each half's median, and return `Q3 - Q1`. For odd lengths, the middle value is excluded from both halves.

The `i64_array_float64` ABI accepts a direct signed 64-bit array of values, with length from 2 through 64 and each value in `[-1,000,000, 1,000,000]`. Inputs are integers; the binary64 result can be an integer or a half integer. This bounded grid keeps Python's average-of-two formula and Rust's `f64::midpoint` behavior identical and prevents overflow. Inputs outside the bounds, including empty and singleton arrays, return `-1e300`. The source explicitly rejects an empty list; a singleton cannot provide nonempty lower and upper halves, so it also falls outside this benchmark contract.

The ports copy values into fixed local storage and insertion-sort them in ascending order. For a valid length `n`, each half has `floor(n/2)` values. The upper half begins at index `floor(n/2)` for even `n`, and at `floor(n/2)+1` for odd `n`. Runtime is O(n²) for the bounded insertion sort and auxiliary space is O(n). The workload includes the pinned examples, odd/even splits, negative and duplicate values, the maximum length, and invalid inputs.

The Rust source uses a total-order fallback when comparing unordered floating-point values. The bounded integer ABI excludes NaN and infinity, so the workload covers the common finite numeric domain shared with Python.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/i/interquartile_range.c](../../../c/i/interquartile_range.c) |
| C3 | [c3/i/interquartile_range.c3](../../../c3/i/interquartile_range.c3) |
| C++ | [cpp/i/interquartile_range.cpp](../../../cpp/i/interquartile_range.cpp) |
| Elisa | [elisa/i/interquartile_range.elisa](../../../elisa/i/interquartile_range.elisa) |
| Nim | [nim/i/interquartile_range.nim](../../../nim/i/interquartile_range.nim) |
| Odin | [odin/i/interquartile_range.odin](../../../odin/i/interquartile_range.odin) |
| Rust | [rust/i/interquartile_range.rs](../../../rust/i/interquartile_range.rs) |
| V | [v/i/interquartile_range.v](../../../v/i/interquartile_range.v) |
| Zig | [zig/i/interquartile_range.zig](../../../zig/i/interquartile_range.zig) |
