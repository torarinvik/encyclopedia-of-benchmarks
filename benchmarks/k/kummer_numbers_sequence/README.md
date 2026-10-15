# Kummer numbers sequence

## Contract

The input is a zero-based index `n` from 0 through 14. Return one less than the product of the first `n + 1` primes. The sequence begins `1, 5, 29, 209, 2,309, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t kummer_numbers_sequence(int64_t index)`. Index 14 uses the first 15 primes through 47; their product is `614,889,782,588,491,410`, so the returned term `614,889,782,588,491,409` fits signed 64-bit output. Index 15 adds prime 53, producing a term larger than `INT64_MAX`. Ports enumerate primes in ascending order and preserve the source's primorial-minus-one construction.

## Source behavior and related sequences

The pinned C# generator skips the first item of `PrimorialNumbersSequence`, which is the empty product 1, then subtracts one from each remaining primorial. Thus its first term uses the first prime: `2 - 1 = 1`. The benchmark uses zero-based indexing into that infinite sequence and bounds it to terms that fit signed 64-bit output.

This differs from `euclid_numbers_sequence`, which retains the empty product and adds one to each primorial. Kummer terms begin `1, 5, 29, ...`; the pinned Euclid sequence begins `2, 3, 7, ...`.

## Workload

[`workload.json`](workload.json) covers the first terms, later primorial products, the largest supported term, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/kummer_numbers_sequence.c`](../../../c/kummer_numbers_sequence.c) |
| C3 | [`c3/k/kummer_numbers_sequence.c3`](../../../c3/k/kummer_numbers_sequence.c3) |
| C++ | [`cpp/k/kummer_numbers_sequence.cpp`](../../../cpp/k/kummer_numbers_sequence.cpp) |
| Elisa | [`elisa/k/kummer_numbers_sequence.elisa`](../../../elisa/k/kummer_numbers_sequence.elisa) |
| Nim | [`nim/k/kummer_numbers_sequence.nim`](../../../nim/k/kummer_numbers_sequence.nim) |
| Odin | [`odin/k/kummer_numbers_sequence.odin`](../../../odin/k/kummer_numbers_sequence.odin) |
| Rust | [`rust/k/kummer_numbers_sequence.rs`](../../../rust/k/kummer_numbers_sequence.rs) |
| V | [`v/k/kummer_numbers_sequence.v`](../../../v/k/kummer_numbers_sequence.v) |
| Zig | [`zig/k/kummer_numbers_sequence.zig`](../../../zig/k/kummer_numbers_sequence.zig) |

## TheAlgorithms references

- [C# `KummerNumbersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/KummerNumbersSequence.cs)
- [C# `PrimorialNumbersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimorialNumbersSequence.cs)
- [C# `PrimesSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimesSequence.cs)
