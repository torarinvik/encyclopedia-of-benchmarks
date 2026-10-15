# Tribonacci numbers sequence

## Contract

Return the zero-based term of the Tribonacci sequence with `T(0) = T(1) = T(2) = 1` and `T(n) = T(n-1) + T(n-2) + T(n-3)`. Supported indices are 0 through 60; other inputs return `-1`. The exported C ABI entry point is `int64_t tribonacci_numbers_sequence(int64_t index);`.

## Source review

The pinned C# `TribonacciNumbersSequence` initializes a four-element buffer to ones, yields `buffer[0]`, then updates only the first three entries using their sum. The fourth initial value is unused. The resulting sequence begins `1, 1, 1, 3, 5, 9, 17, ...`. The benchmark uses a constant-space recurrence to return an indexed term. This source is distinct from the existing `tribonacci` benchmark, which starts `0, 1, 1`.

The index cap of 60 keeps every result within signed 64-bit range; `T(60) = 3,296,634,657,589,821`.

## Workload

[`workload.json`](workload.json) covers the three source seed terms, early and later recurrence values, the largest supported index, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/tribonacci_numbers_sequence.c`](../../../c/t/tribonacci_numbers_sequence.c) |
| C3 | [`c3/t/tribonacci_numbers_sequence.c3`](../../../c3/t/tribonacci_numbers_sequence.c3) |
| C++ | [`cpp/t/tribonacci_numbers_sequence.cpp`](../../../cpp/t/tribonacci_numbers_sequence.cpp) |
| Elisa | [`elisa/t/tribonacci_numbers_sequence.elisa`](../../../elisa/t/tribonacci_numbers_sequence.elisa) |
| Nim | [`nim/t/tribonacci_numbers_sequence.nim`](../../../nim/t/tribonacci_numbers_sequence.nim) |
| Odin | [`odin/t/tribonacci_numbers_sequence.odin`](../../../odin/t/tribonacci_numbers_sequence.odin) |
| Rust | [`rust/t/tribonacci_numbers_sequence.rs`](../../../rust/t/tribonacci_numbers_sequence.rs) |
| V | [`v/t/tribonacci_numbers_sequence.v`](../../../v/t/tribonacci_numbers_sequence.v) |
| Zig | [`zig/t/tribonacci_numbers_sequence.zig`](../../../zig/t/tribonacci_numbers_sequence.zig) |

## TheAlgorithms reference

- [C# `TribonacciNumbersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/TribonacciNumbersSequence.cs)
