# Matchstick triangle sequence

## Contract

The input is a zero-based index `n` from `0` through `1,000,000`. Return

```text
floor(n * (n + 2) * (2n + 1) / 8)
```

using integer division. The sequence begins `0, 1, 5, 13, 27, 48, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t matchstick_triangle_sequence(int64_t n)`. At the maximum supported index, the numerator is `2,000,005,000,002,000,000`, which fits signed 64-bit arithmetic. The bound keeps the source formula exact and portable through the scalar ABI.

## Source behavior

The pinned C# `MatchstickTriangleSequence` starts at index zero and emits `BigInteger.Divide(n * (n + 2) * (2n + 1), 8)`, then increments the index. Its documentation mentions a correction term, but the implementation directly divides this product by eight; the benchmark preserves the executable expression and its truncating integer division. The sequence generator is infinite and has no invalid-input behavior; the benchmark maps indices outside 0..1,000,000 to `-1`.

## Workload

[`workload.json`](workload.json) covers the source's zero term, early triangle arrangements, a larger term, the largest supported index, and invalid inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/matchstick_triangle_sequence.c`](../../../c/m/matchstick_triangle_sequence.c) |
| C3 | [`c3/m/matchstick_triangle_sequence.c3`](../../../c3/m/matchstick_triangle_sequence.c3) |
| C++ | [`cpp/m/matchstick_triangle_sequence.cpp`](../../../cpp/m/matchstick_triangle_sequence.cpp) |
| Elisa | [`elisa/m/matchstick_triangle_sequence.elisa`](../../../elisa/m/matchstick_triangle_sequence.elisa) |
| Nim | [`nim/m/matchstick_triangle_sequence.nim`](../../../nim/m/matchstick_triangle_sequence.nim) |
| Odin | [`odin/m/matchstick_triangle_sequence.odin`](../../../odin/m/matchstick_triangle_sequence.odin) |
| Rust | [`rust/m/matchstick_triangle_sequence.rs`](../../../rust/m/matchstick_triangle_sequence.rs) |
| V | [`v/m/matchstick_triangle_sequence.v`](../../../v/m/matchstick_triangle_sequence.v) |
| Zig | [`zig/m/matchstick_triangle_sequence.zig`](../../../zig/m/matchstick_triangle_sequence.zig) |

## TheAlgorithms reference

- [C# `MatchstickTriangleSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/MatchstickTriangleSequence.cs)
