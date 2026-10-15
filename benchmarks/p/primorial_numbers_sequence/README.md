# Primorial numbers sequence

## Contract

The input is a zero-based index `n` from 0 through 15. Return the product of the first `n` primes, with the empty product at index 0 equal to 1. The sequence begins `1, 2, 6, 30, 210, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t primorial_numbers_sequence(int64_t index)`. Index 15 is the product of the first 15 primes through 47, `614,889,782,588,491,410`, which fits signed 64-bit output. Index 16 would multiply by 53 and exceed `INT64_MAX`. Ports enumerate primes in ascending order and multiply each into the running product.

## Source behavior and related sequences

The pinned C# generator initializes its product to 1, then for each prime yields the current product before multiplying by that prime. This makes the first yielded term the empty product 1. The local contract uses zero-based positions in this generator and bounds it before signed 64-bit overflow.

This returns the primorial products themselves. `kummer_numbers_sequence` skips the empty product and subtracts one from each later primorial; `euclid_numbers_sequence` adds one to its primorial terms. Their outputs are different sequences.

## Workload

[`workload.json`](workload.json) covers the empty product, early primorials, a later product, the largest supported term, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/primorial_numbers_sequence.c`](../../../c/p/primorial_numbers_sequence.c) |
| C3 | [`c3/p/primorial_numbers_sequence.c3`](../../../c3/p/primorial_numbers_sequence.c3) |
| C++ | [`cpp/p/primorial_numbers_sequence.cpp`](../../../cpp/p/primorial_numbers_sequence.cpp) |
| Elisa | [`elisa/p/primorial_numbers_sequence.elisa`](../../../elisa/p/primorial_numbers_sequence.elisa) |
| Nim | [`nim/p/primorial_numbers_sequence.nim`](../../../nim/p/primorial_numbers_sequence.nim) |
| Odin | [`odin/p/primorial_numbers_sequence.odin`](../../../odin/p/primorial_numbers_sequence.odin) |
| Rust | [`rust/p/primorial_numbers_sequence.rs`](../../../rust/p/primorial_numbers_sequence.rs) |
| V | [`v/p/primorial_numbers_sequence.v`](../../../v/p/primorial_numbers_sequence.v) |
| Zig | [`zig/p/primorial_numbers_sequence.zig`](../../../zig/p/primorial_numbers_sequence.zig) |

## TheAlgorithms references

- [C# `PrimorialNumbersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimorialNumbersSequence.cs)
- [C# `PrimesSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimesSequence.cs)
