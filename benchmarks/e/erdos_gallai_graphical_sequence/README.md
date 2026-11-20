# Erdős–Gallai graphical-sequence test

Determine whether a bounded integer sequence is the degree sequence of a
simple undirected graph. Input is `[n, d0, ..., d(n-1)]`, with `0 <= n <= 256`
and every degree in `0..n-1`. Return `1` for a graphical sequence, `0` for a
valid sequence that is not graphical, and `-1` for an invalid frame or degree.
The empty sequence is graphical.

The implementation sorts degrees in nonincreasing order and checks the
Erdős–Gallai inequalities. Prefix sums and a binary search find the point in
each tail where degrees drop below `k`, allowing the right-hand sum of
`min(k, d_i)` to be evaluated in `O(log n)` per inequality. Total time is
`O(n log n)` and scratch storage is `O(n)`. The primary oracle uses this
inequality check; the independent oracle repeatedly applies Havel–Hakimi.

The [Erdős–Gallai characterization](https://web.iitd.ac.in/~atripath/publications/constructive_Erdos-Gallai.pdf)
decides realizability of a degree sequence; it does not construct or color a
graph or test connectivity. The theorem is used as an algorithm reference
only. Contracts, references, fixtures, and all language ports are clean-room.

| Language | Port |
|---|---|
| C | [c/e/erdos_gallai_graphical_sequence.c](../../../c/e/erdos_gallai_graphical_sequence.c) |
| C3 | [c3/e/erdos_gallai_graphical_sequence.c3](../../../c3/e/erdos_gallai_graphical_sequence.c3) |
| C++ | [cpp/e/erdos_gallai_graphical_sequence.cpp](../../../cpp/e/erdos_gallai_graphical_sequence.cpp) |
| Elisa | [elisa/e/erdos_gallai_graphical_sequence.elisa](../../../elisa/e/erdos_gallai_graphical_sequence.elisa) |
| Mojo | [mojo/e/erdos_gallai_graphical_sequence.mojo](../../../mojo/e/erdos_gallai_graphical_sequence.mojo) |
| Nim | [nim/e/erdos_gallai_graphical_sequence.nim](../../../nim/e/erdos_gallai_graphical_sequence.nim) |
| Odin | [odin/e/erdos_gallai_graphical_sequence.odin](../../../odin/e/erdos_gallai_graphical_sequence.odin) |
| Rust | [rust/e/erdos_gallai_graphical_sequence.rs](../../../rust/e/erdos_gallai_graphical_sequence.rs) |
| V | [v/e/erdos_gallai_graphical_sequence.v](../../../v/e/erdos_gallai_graphical_sequence.v) |
| Zig | [zig/e/erdos_gallai_graphical_sequence.zig](../../../zig/e/erdos_gallai_graphical_sequence.zig) |
