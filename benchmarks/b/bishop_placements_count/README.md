# Nonattacking bishop placement count

Count the exact number of ways to place `K` indistinguishable bishops on an
`N x N` board so no two attack each other. The primary ports count placements
separately on the two square colors. Within one color, a diagonal of size `s`
can take the next bishop in `s-j+1` ways after `j-1` bishops have been placed
on earlier diagonals of that color. The two color classes are independent, so
their counts are combined over every split of `K`.

## Contract

The exported scalar ABI symbol is `bishop_placements_count`. Input is the
two-word signed 64-bit array `[N,K]`, with `1<=N<=8` and `0<=K<=16`. The
maximum number of nonattacking bishops is 1 for `N=1` and `2N-2` otherwise;
larger `K` within the input bound returns zero. Malformed or out-of-profile
input returns `-1`. The result is an exact signed 64-bit placement count.

For the largest board, every result is bounded by the number of `K`-square
subsets of 64 squares, at most `C(64,32)`, which fits in signed 64-bit. The
primary recurrence takes `O(NK)` time and `O(NK)` space. The independent
verifier processes one diagonal family at a time and uses a mask for occupied
diagonals of the other family, taking `O(N^2 2^(2N))` time and
`O(2^(2N))` space at these small bounds.

## Distinctness and provenance

[`n_queens_solution_count`](../../n/n_queens_solution_count/README.md) counts queen
placements and tracks row, column, and both diagonal conflicts. [`queens`](../../q/queens/README.md)
also searches queen placements. Neither counts bishops, which attack along
diagonals only, and neither uses the color-separated diagonal-size recurrence.
Graph coloring and Burnside orbit-count packages solve different problems.

The algorithm description comes from [CP-Algorithms, “Placing Bishops on a
Chessboard”](https://cp-algorithms.com/combinatorics/bishops-on-chessboard.html),
licensed under CC BY-SA 4.0. This package uses only the high-level recurrence
description; the bounded contract, fixtures, independent oracle, and ten
ports are clean-room work. No article code or prose was copied.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[primary oracle](../../bishop_placements_count_oracle.py), the
[independent verifier](../../bishop_placements_count_verifier_oracle.py), and
the package-local [static inventory checker](../../check_bishop_placements_count_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/bishop_placements_count.c`](../../../c/b/bishop_placements_count.c) |
| C3 | [`c3/b/bishop_placements_count.c3`](../../../c3/b/bishop_placements_count.c3) |
| C++ | [`cpp/b/bishop_placements_count.cpp`](../../../cpp/b/bishop_placements_count.cpp) |
| Elisa | [`elisa/b/bishop_placements_count.elisa`](../../../elisa/b/bishop_placements_count.elisa) |
| Mojo | [`mojo/b/bishop_placements_count.mojo`](../../../mojo/b/bishop_placements_count.mojo) |
| Nim | [`nim/b/bishop_placements_count.nim`](../../../nim/b/bishop_placements_count.nim) |
| Odin | [`odin/b/bishop_placements_count.odin`](../../../odin/b/bishop_placements_count.odin) |
| Rust | [`rust/b/bishop_placements_count.rs`](../../../rust/b/bishop_placements_count.rs) |
| V | [`v/b/bishop_placements_count.v`](../../../v/b/bishop_placements_count.v) |
| Zig | [`zig/b/bishop_placements_count.zig`](../../../zig/b/bishop_placements_count.zig) |
