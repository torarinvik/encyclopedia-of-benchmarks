# Number of Boolean functions sequence

## Contract

The input is a zero-based index `n` from 0 through 5. Return `2^(2^n)`, the number of Boolean functions on `n` variables; the terms are `2, 4, 16, 256, 65,536, 4,294,967,296`. Return `-1` outside the supported range.

The scalar ABI is `int64_t number_of_boolean_functions_sequence(int64_t index)`. The upper bound follows from signed 64-bit output: index 5 yields `2^32`, while index 6 yields `2^64`, which is out of range. Ports preserve the source's repeated-squaring construction.

## Source behavior and related algorithms

The pinned C# generator initializes a `BigInteger` term to 2, yields it, then squares it for each later term. Its first item therefore corresponds to zero variables and is 2; it is not initialized with one Boolean function. The local scalar contract indexes this generator from zero and applies the i64 bound.

This counts possible Boolean functions for a variable count. It is distinct from Boolean gate evaluation, which computes the output of a particular logical expression on supplied inputs.

## Workload

[`workload.json`](workload.json) covers every supported term and invalid indices outside the domain.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/number_of_boolean_functions_sequence.c`](../../../c/n/number_of_boolean_functions_sequence.c) |
| C3 | [`c3/n/number_of_boolean_functions_sequence.c3`](../../../c3/n/number_of_boolean_functions_sequence.c3) |
| C++ | [`cpp/n/number_of_boolean_functions_sequence.cpp`](../../../cpp/n/number_of_boolean_functions_sequence.cpp) |
| Elisa | [`elisa/n/number_of_boolean_functions_sequence.elisa`](../../../elisa/n/number_of_boolean_functions_sequence.elisa) |
| Nim | [`nim/n/number_of_boolean_functions_sequence.nim`](../../../nim/n/number_of_boolean_functions_sequence.nim) |
| Odin | [`odin/n/number_of_boolean_functions_sequence.odin`](../../../odin/n/number_of_boolean_functions_sequence.odin) |
| Rust | [`rust/n/number_of_boolean_functions_sequence.rs`](../../../rust/n/number_of_boolean_functions_sequence.rs) |
| V | [`v/n/number_of_boolean_functions_sequence.v`](../../../v/n/number_of_boolean_functions_sequence.v) |
| Zig | [`zig/n/number_of_boolean_functions_sequence.zig`](../../../zig/n/number_of_boolean_functions_sequence.zig) |

## TheAlgorithms reference

- [C# `NumberOfBooleanFunctionsSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/NumberOfBooleanFunctionsSequence.cs)
