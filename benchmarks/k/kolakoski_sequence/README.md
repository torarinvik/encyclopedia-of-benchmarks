# Kolakoski sequence

Return a zero-based term from the Kolakoski sequence, which consists of 1s and 2s and is its own run-length sequence. The prefix begins `1, 2, 2, 1, 1, 2, 1, 2, 2, 1, ...`.

## Contract

- The scalar ABI is `int64_t kolakoski_sequence(int64_t index)`.
- Indices 0 through 63 are supported. Negative indices and indices above 63 return `-1`.
- Index 0 is the first yielded source term, 1. Every valid result is 1 or 2.
- The bound keeps the generated prefix within one unsigned 64-bit word in these ports; the pinned source itself is an unbounded iterator.

## Source behavior

The pinned C# `KolakoskiSequence` yields `1, 2, 2`, seeds its queue with run length 2, then emits the alternating symbols 1 and 2 according to each queued run length. Each emitted symbol is queued as a later run length. The ports preserve that recurrence and pack the generated 1/2 terms into a 64-bit word, with a set bit representing term 2.

The pinned C# `KolakoskiSequence2` is an alternate lazy implementation of the same mathematical sequence, so it maps to this sequence contract rather than defining a separate sequence.

## Workload

[`workload.json`](workload.json) covers the seed, early transitions, later terms, both supported boundaries, and invalid indices.

Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm kolakoski_sequence --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/k/kolakoski_sequence/c/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/kolakoski_sequence.c`](../../../c/k/kolakoski_sequence.c) |
| C3 | [`c3/k/kolakoski_sequence.c3`](../../../c3/k/kolakoski_sequence.c3) |
| C++ | [`cpp/k/kolakoski_sequence.cpp`](../../../cpp/k/kolakoski_sequence.cpp) |
| Elisa | [`elisa/k/kolakoski_sequence.elisa`](../../../elisa/k/kolakoski_sequence.elisa) |
| Nim | [`nim/k/kolakoski_sequence.nim`](../../../nim/k/kolakoski_sequence.nim) |
| Odin | [`odin/k/kolakoski_sequence.odin`](../../../odin/k/kolakoski_sequence.odin) |
| Rust | [`rust/k/kolakoski_sequence.rs`](../../../rust/k/kolakoski_sequence.rs) |
| V | [`v/k/kolakoski_sequence.v`](../../../v/k/kolakoski_sequence.v) |
| Zig | [`zig/k/kolakoski_sequence.zig`](../../../zig/k/kolakoski_sequence.zig) |

## TheAlgorithms reference

- [C# `KolakoskiSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/KolakoskiSequence.cs)
- [C# `KolakoskiSequence2.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/KolakoskiSequence2.cs)
