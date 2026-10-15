# Cake numbers sequence

## Contract

The input is a zero-based sequence index from `0` through `2,000,000`. Return

```text
(n^3 + 5n + 6) / 6
```

using integer division. The sequence begins `1, 2, 4, 8, 15, 26, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t cake_numbers_sequence(int64_t n)`. At the maximum index, the numerator is `8,000,000,000,010,006`, which fits signed 64-bit arithmetic; the result is exact. The bound limits the source's arbitrary-precision sequence to values and intermediates portable through the shared signed 64-bit ABI.

## Source behavior and related sequences

The pinned C# `CakeNumbersSequence` starts its index at zero and computes the same closed form with `BigInteger.Pow`, then increments the index after producing each term. The source sequence is infinite and has no invalid-input behavior; the benchmark maps indices outside 0..2,000,000 to `-1`.

Cake numbers count the maximum pieces from planar cuts through a cake or cube. This is distinct from the central polygonal sequence already in the benchmark set: their terms coincide at indices 0, 1, and 2, then differ beginning at index 3.

## Workload

[`workload.json`](workload.json) covers the zero-index base term, early sequence terms, a larger index, the bound, and invalid values.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/cake_numbers_sequence.c`](../../../c/c/cake_numbers_sequence.c) |
| C3 | [`c3/c/cake_numbers_sequence.c3`](../../../c3/c/cake_numbers_sequence.c3) |
| C++ | [`cpp/c/cake_numbers_sequence.cpp`](../../../cpp/c/cake_numbers_sequence.cpp) |
| Elisa | [`elisa/c/cake_numbers_sequence.elisa`](../../../elisa/c/cake_numbers_sequence.elisa) |
| Nim | [`nim/c/cake_numbers_sequence.nim`](../../../nim/c/cake_numbers_sequence.nim) |
| Odin | [`odin/c/cake_numbers_sequence.odin`](../../../odin/c/cake_numbers_sequence.odin) |
| Rust | [`rust/c/cake_numbers_sequence.rs`](../../../rust/c/cake_numbers_sequence.rs) |
| V | [`v/c/cake_numbers_sequence.v`](../../../v/c/cake_numbers_sequence.v) |
| Zig | [`zig/c/cake_numbers_sequence.zig`](../../../zig/c/cake_numbers_sequence.zig) |

## TheAlgorithms reference

- [C# `CakeNumbersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/CakeNumbersSequence.cs)
