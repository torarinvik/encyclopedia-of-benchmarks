# Primes sequence

## Contract

Return the zero-based prime term: index 0 is 2, index 1 is 3, index 2 is 5, and so on. Supported indices are 0 through 99; other inputs return `-1`. The exported C ABI entry point is `int64_t primes_sequence(int64_t index);`.

## Source review

The pinned C# generator yields 2 first, then examines odd candidates from 3 upward. For each candidate it tests divisibility by every prime already yielded, appends a candidate only when none divide it, and then advances by two. The ports preserve that generator strategy, including checking all prior primes rather than stopping at the square root. Index 99 is 541. The bound keeps the source's retained-prime list and work per scalar call small.

## Workload

[`workload.json`](workload.json) covers the initial terms, representative later primes, the largest supported index, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/primes_sequence.c`](../../../c/p/primes_sequence.c) |
| C3 | [`c3/p/primes_sequence.c3`](../../../c3/p/primes_sequence.c3) |
| C++ | [`cpp/p/primes_sequence.cpp`](../../../cpp/p/primes_sequence.cpp) |
| Elisa | [`elisa/p/primes_sequence.elisa`](../../../elisa/p/primes_sequence.elisa) |
| Nim | [`nim/p/primes_sequence.nim`](../../../nim/p/primes_sequence.nim) |
| Odin | [`odin/p/primes_sequence.odin`](../../../odin/p/primes_sequence.odin) |
| Rust | [`rust/p/primes_sequence.rs`](../../../rust/p/primes_sequence.rs) |
| V | [`v/p/primes_sequence.v`](../../../v/p/primes_sequence.v) |
| Zig | [`zig/p/primes_sequence.zig`](../../../zig/p/primes_sequence.zig) |

## TheAlgorithms reference

- [C# `PrimesSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimesSequence.cs)
