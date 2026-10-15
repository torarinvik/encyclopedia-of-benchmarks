# Tetrahedral sequence

## Contract

The input is a zero-based index `n` from 0 through 3,810,777. Return the tetrahedral number `n(n+1)(n+2)/6`; the sequence begins `0, 1, 4, 10, 20, ...`. Return `-1` outside that range. The upper bound is the largest index whose tetrahedral number fits signed 64-bit output.

The scalar ABI is `int64_t tetrahedral_sequence(int64_t index)`. The largest supported term is 9,223,371,416,043,870,029. The next term exceeds `INT64_MAX`. To avoid overflow in intermediate multiplication, ports divide the three consecutive factors by 2 and 3 before multiplying.

## Source behavior

The pinned C# generator starts at index 0 and yields `index * (index + 1) * (index + 2) / 6`, then increments the index. The benchmark uses zero-based indexing into that sequence.

## Related sequences

[`square_pyramidal_numbers`](../../s/square_pyramidal_numbers/README.md) sums square layers, while this sequence gives tetrahedral counts (sums of triangular layers).

## Workload

[`workload.json`](workload.json) covers initial terms, a later term, the largest signed 64-bit term, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/tetrahedral_sequence.c`](../../../c/t/tetrahedral_sequence.c) |
| C3 | [`c3/t/tetrahedral_sequence.c3`](../../../c3/t/tetrahedral_sequence.c3) |
| C++ | [`cpp/t/tetrahedral_sequence.cpp`](../../../cpp/t/tetrahedral_sequence.cpp) |
| Elisa | [`elisa/t/tetrahedral_sequence.elisa`](../../../elisa/t/tetrahedral_sequence.elisa) |
| Nim | [`nim/t/tetrahedral_sequence.nim`](../../../nim/t/tetrahedral_sequence.nim) |
| Odin | [`odin/t/tetrahedral_sequence.odin`](../../../odin/t/tetrahedral_sequence.odin) |
| Rust | [`rust/t/tetrahedral_sequence.rs`](../../../rust/t/tetrahedral_sequence.rs) |
| V | [`v/t/tetrahedral_sequence.v`](../../../v/t/tetrahedral_sequence.v) |
| Zig | [`zig/t/tetrahedral_sequence.zig`](../../../zig/t/tetrahedral_sequence.zig) |

## TheAlgorithms reference

- [C# `TetrahedralSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/TetrahedralSequence.cs)
