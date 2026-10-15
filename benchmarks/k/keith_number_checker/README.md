# Keith number checker

## Contract

Return `1` when the source's digit-window sequence reaches the input exactly, and `0` when its first generated sum exceeds the input. The supported input range is 2 through 1,000; values outside it return `-1`. The exported C ABI entry point is `int64_t keith_number_checker(int64_t number);`.

## Source review

The pinned C# method stores the input's decimal digits from least-significant to most-significant in reverse positions, then repeatedly sums the latest `digitCount` terms until the sum is at least the input. The benchmark preserves that recurrence and return comparison. This source has edge behavior worth recording: it returns true for one-digit inputs 2 through 9, while inputs 0 and 1 throw due to writing beyond the `int[number]` array; negative inputs throw an `ArgumentException`. The benchmark maps 0, 1, negative values, and values above 1,000 to the invalid sentinel. The bound keeps the source's per-input array allocation modest and all generated `int` sums far from overflow.

## Workload

[`workload.json`](workload.json) includes the one-digit source behavior, known Keith numbers, non-matches, and both ends of the supported range.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/keith_number_checker.c`](../../../c/k/keith_number_checker.c) |
| C3 | [`c3/k/keith_number_checker.c3`](../../../c3/k/keith_number_checker.c3) |
| C++ | [`cpp/k/keith_number_checker.cpp`](../../../cpp/k/keith_number_checker.cpp) |
| Elisa | [`elisa/k/keith_number_checker.elisa`](../../../elisa/k/keith_number_checker.elisa) |
| Nim | [`nim/k/keith_number_checker.nim`](../../../nim/k/keith_number_checker.nim) |
| Odin | [`odin/k/keith_number_checker.odin`](../../../odin/k/keith_number_checker.odin) |
| Rust | [`rust/k/keith_number_checker.rs`](../../../rust/k/keith_number_checker.rs) |
| V | [`v/k/keith_number_checker.v`](../../../v/k/keith_number_checker.v) |
| Zig | [`zig/k/keith_number_checker.zig`](../../../zig/k/keith_number_checker.zig) |

## TheAlgorithms reference

- [C# `KeithNumberChecker.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/KeithNumberChecker.cs)
