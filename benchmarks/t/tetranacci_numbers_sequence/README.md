# Tetranacci numbers sequence

## Contract

The input is a zero-based index `n` from 0 through 68. Return the tetranacci term with initial values `a(0)=a(1)=a(2)=a(3)=1` and recurrence `a(n)=a(n-1)+a(n-2)+a(n-3)+a(n-4)`. The sequence begins `1, 1, 1, 1, 4, 7, 13, 25, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t tetranacci_numbers_sequence(int64_t index)`. Term 68 is `6,143,283,409,278,911,809`, which fits signed 64-bit output; term 69 is `11,841,559,504,341,139,582`, which does not. Implementations keep the latest four terms and apply the source's left-to-right four-term sum.

## Source behavior and related sequences

The pinned C# generator initializes a four-element buffer to ones, yields its first element, then sums all four entries and shifts the buffer. The benchmark uses zero-based indexing into that generator.

This differs from Tribonacci, which sums three previous terms and uses different initial terms. Here all first four values are one, and the fourth-order recurrence first produces 4 at index 4.

## Workload

[`workload.json`](workload.json) covers each initial value, early and later recurrence steps, the largest supported term, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/tetranacci_numbers_sequence.c`](../../../c/t/tetranacci_numbers_sequence.c) |
| C3 | [`c3/t/tetranacci_numbers_sequence.c3`](../../../c3/t/tetranacci_numbers_sequence.c3) |
| C++ | [`cpp/t/tetranacci_numbers_sequence.cpp`](../../../cpp/t/tetranacci_numbers_sequence.cpp) |
| Elisa | [`elisa/t/tetranacci_numbers_sequence.elisa`](../../../elisa/t/tetranacci_numbers_sequence.elisa) |
| Nim | [`nim/t/tetranacci_numbers_sequence.nim`](../../../nim/t/tetranacci_numbers_sequence.nim) |
| Odin | [`odin/t/tetranacci_numbers_sequence.odin`](../../../odin/t/tetranacci_numbers_sequence.odin) |
| Rust | [`rust/t/tetranacci_numbers_sequence.rs`](../../../rust/t/tetranacci_numbers_sequence.rs) |
| V | [`v/t/tetranacci_numbers_sequence.v`](../../../v/t/tetranacci_numbers_sequence.v) |
| Zig | [`zig/t/tetranacci_numbers_sequence.zig`](../../../zig/t/tetranacci_numbers_sequence.zig) |

## TheAlgorithms reference

- [C# `TetranacciNumbersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/TetranacciNumbersSequence.cs)
