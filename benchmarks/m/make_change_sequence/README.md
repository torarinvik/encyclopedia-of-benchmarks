# Make change sequence

## Contract

The input is a cents amount `n` from 0 through 128. Return the number of ways to make that amount using unlimited coins of 1, 2, 5, and 10 cents. The sequence begins `1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 11, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t make_change_sequence(int64_t amount)`. The benchmark keeps the source's first 17 terms and recurrence, which remains well within signed 64-bit range over this bounded domain. For indices `n >= 17`, the source computes, in order:

```text
a[n-2] + a[n-5] - a[n-7] + a[n-10] - a[n-12] - a[n-15] + a[n-17] + 1
```

## Source behavior and related algorithms

The pinned C# sequence explicitly seeds `a(0)` through `a(16)` with `[1,1,2,2,3,4,5,6,7,8,11,12,15,16,19,22,25]`, then applies the recurrence above. The local ports preserve both the seed and the exact left-to-right operation order. These terms count combinations for fixed denominations 1, 2, 5, and 10.

This is distinct from the generic `coin_change` benchmark, which accepts a caller-provided denomination list and returns the minimum number of coins rather than a combination count.

## Workload

[`workload.json`](workload.json) covers the initial seed, recurrence-produced terms, the largest supported amount, and invalid amounts.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/make_change_sequence.c`](../../../c/m/make_change_sequence.c) |
| C3 | [`c3/m/make_change_sequence.c3`](../../../c3/m/make_change_sequence.c3) |
| C++ | [`cpp/m/make_change_sequence.cpp`](../../../cpp/m/make_change_sequence.cpp) |
| Elisa | [`elisa/m/make_change_sequence.elisa`](../../../elisa/m/make_change_sequence.elisa) |
| Nim | [`nim/m/make_change_sequence.nim`](../../../nim/m/make_change_sequence.nim) |
| Odin | [`odin/m/make_change_sequence.odin`](../../../odin/m/make_change_sequence.odin) |
| Rust | [`rust/m/make_change_sequence.rs`](../../../rust/m/make_change_sequence.rs) |
| V | [`v/m/make_change_sequence.v`](../../../v/m/make_change_sequence.v) |
| Zig | [`zig/m/make_change_sequence.zig`](../../../zig/m/make_change_sequence.zig) |

## TheAlgorithms reference

- [C# `MakeChangeSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/MakeChangeSequence.cs)
