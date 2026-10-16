# Maximum Consecutive Ones III

Return the longest contiguous window containing at most `k` zeroes, interpreted as ones after flipping those zeroes.

## Contract

The `i64_array_scalar` ABI encodes `[n, k, bits...]`. `n` is 1–1024, `k` is 0–`n`, and each bit is 0 or 1. Invalid shape, bounds, or bit values return `-2`.

## Source semantics

This follows the pinned [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Sliding-Window/MaxConsecutiveOnesIII.js). It uses a sliding window and returns the maximum window length. The source shrink loop checks `slowPointer === 0` where it needs to inspect the value being removed; the benchmark ports the intended at-most-`k`-zero window rule. Its empty-array case returns 0, while the bounded workload requires at least one element.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/max_consecutive_ones_iii.c](../../../c/m/max_consecutive_ones_iii.c) |
| C3 | [c3/m/max_consecutive_ones_iii.c3](../../../c3/m/max_consecutive_ones_iii.c3) |
| C++ | [cpp/m/max_consecutive_ones_iii.cpp](../../../cpp/m/max_consecutive_ones_iii.cpp) |
| Elisa | [elisa/m/max_consecutive_ones_iii.elisa](../../../elisa/m/max_consecutive_ones_iii.elisa) |
| Nim | [nim/m/max_consecutive_ones_iii.nim](../../../nim/m/max_consecutive_ones_iii.nim) |
| Odin | [odin/m/max_consecutive_ones_iii.odin](../../../odin/m/max_consecutive_ones_iii.odin) |
| Rust | [rust/m/max_consecutive_ones_iii.rs](../../../rust/m/max_consecutive_ones_iii.rs) |
| V | [v/m/max_consecutive_ones_iii.v](../../../v/m/max_consecutive_ones_iii.v) |
| Zig | [zig/m/max_consecutive_ones_iii.zig](../../../zig/m/max_consecutive_ones_iii.zig) |

The package uses the `i64_array_scalar` benchmark ABI.
