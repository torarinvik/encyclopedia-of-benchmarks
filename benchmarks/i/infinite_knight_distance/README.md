# Infinite Knight Distance

Return the shortest number of knight moves between two points on the infinite
integer grid. This constant-time distance transform is distinct from the local
finite-board knight-tour benchmarks, which enumerate tours instead of measuring
an unbounded-board displacement.

## Contract

Input is `[dx, dy]`, where each signed 64-bit displacement is in
`[-1,000,000,000, 1,000,000,000]`. The result is the minimum number of knight
moves; malformed arrays, null input, and out-of-range coordinates return `-1`.
The maximum distance in the bounded square is `666,666,668`. The method uses
constant workspace.

## Distance formula

Let `M = max(|dx|, |dy|)` and `m = min(|dx|, |dy|)`. Except for two nearby
displacements, begin with

`b = max(ceil(M/2), ceil((M+m)/3))`.

Every move changes the parity of the coordinate sum, so increase `b` by one
when needed to make its parity equal to `M+m`. The exact exceptions are
`(M,m)=(1,0)`, whose distance is 3, and `(M,m)=(2,2)`, whose distance is 4.
The formula is from Das and Chatterji's [knight-distance paper](https://doi.org/10.1016/0167-8655(88)90105-5).

The independent reference performs bounded BFS for all displacements with
`max(|dx|,|dy|) <= 8`. Larger workload points are directly calculated from the
published formula and recorded as fixed fixtures. See [`RIGHTS.md`](RIGHTS.md)
and [`INVENTORY.md`](INVENTORY.md).

| Language | Source |
| --- | --- |
| C | [`c/i/infinite_knight_distance.c`](../../../c/i/infinite_knight_distance.c) |
| C3 | [`c3/i/infinite_knight_distance.c3`](../../../c3/i/infinite_knight_distance.c3) |
| C++ | [`cpp/i/infinite_knight_distance.cpp`](../../../cpp/i/infinite_knight_distance.cpp) |
| Elisa | [`elisa/i/infinite_knight_distance.elisa`](../../../elisa/i/infinite_knight_distance.elisa) |
| Mojo | [`mojo/i/infinite_knight_distance.mojo`](../../../mojo/i/infinite_knight_distance.mojo) |
| Nim | [`nim/i/infinite_knight_distance.nim`](../../../nim/i/infinite_knight_distance.nim) |
| Odin | [`odin/i/infinite_knight_distance.odin`](../../../odin/i/infinite_knight_distance.odin) |
| Rust | [`rust/i/infinite_knight_distance.rs`](../../../rust/i/infinite_knight_distance.rs) |
| V | [`v/i/infinite_knight_distance.v`](../../../v/i/infinite_knight_distance.v) |
| Zig | [`zig/i/infinite_knight_distance.zig`](../../../zig/i/infinite_knight_distance.zig) |
