# Nth Ugly Number

Return the zero-based `n`th positive integer whose prime factors are all in the fixed base set `[2, 3, 5]`. The sequence begins `1, 2, 3, 4, 5, 6, 8, 9, 10, 12, ...`; `n = 0` returns `1`.

## Contract

- Input is one signed 64-bit integer `n`.
- Inputs from `0` through `12,690` return the value at that zero-based sequence index.
- Negative inputs and inputs above `12,690` return `-1`.
- The upper bound is the last index whose value can be generated without exceeding the signed 64-bit range. The value at index `12,690` is `9,216,000,000,000,000,000`.
- The pinned source accepts a configurable list of bases. This benchmark fixes that list to the canonical `[2, 3, 5]` and preserves the source's ordered value sequence.

## Workload and measurement

[`workload.json`](workload.json) covers the first values, representative indices, the maximum supported index, and both sides of the input range. The scalar runner times repeated calls with one fixed index per case.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/nth_ugly_number.c`](../../../c/n/nth_ugly_number.c) |
| C3 | [`c3/n/nth_ugly_number.c3`](../../../c3/n/nth_ugly_number.c3) |
| C++ | [`cpp/n/nth_ugly_number.cpp`](../../../cpp/n/nth_ugly_number.cpp) |
| Elisa | [`elisa/n/nth_ugly_number.elisa`](../../../elisa/n/nth_ugly_number.elisa) |
| Nim | [`nim/n/nth_ugly_number.nim`](../../../nim/n/nth_ugly_number.nim) |
| Odin | [`odin/n/nth_ugly_number.odin`](../../../odin/n/nth_ugly_number.odin) |
| Rust | [`rust/n/nth_ugly_number.rs`](../../../rust/n/nth_ugly_number.rs) |
| V | [`v/n/nth_ugly_number.v`](../../../v/n/nth_ugly_number.v) |
| Zig | [`zig/n/nth_ugly_number.zig`](../../../zig/n/nth_ugly_number.zig) |

All nine ports use the same candidate sequence and skip duplicate values by advancing every base position that produced the selected minimum.

## Source

The pinned [TheAlgorithms/Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/NthUglyNumber.java) uses a zero-based `get(n)` method. Its constructor accepts a base list; this benchmark fixes it to `[2, 3, 5]`. The shared signed 64-bit scalar ABI exposes the bounded index-to-value operation described above.
