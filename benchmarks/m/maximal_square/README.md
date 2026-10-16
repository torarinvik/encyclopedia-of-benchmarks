# Maximal square

Find the area of the largest all-one square in a binary matrix.

## Contract

The `i64_array_scalar` input is `[rows, columns, cells...]`, with row-major cells. Both dimensions are 1–16, and each cell is 0 or 1. Valid input returns the area; invalid shapes or values return `-1`.

## Source semantics

This follows the pinned [TheAlgorithms Rust implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/maximal_square.rs). It updates each one cell to the largest square side ending there, using the diagonal, upper, and left neighbors, then squares the maximum side. Ports use a one-row DP buffer and return the same area without mutating the input.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/maximal_square.c](../../../c/m/maximal_square.c) |
| C3 | [c3/m/maximal_square.c3](../../../c3/m/maximal_square.c3) |
| C++ | [cpp/m/maximal_square.cpp](../../../cpp/m/maximal_square.cpp) |
| Elisa | [elisa/m/maximal_square.elisa](../../../elisa/m/maximal_square.elisa) |
| Nim | [nim/m/maximal_square.nim](../../../nim/m/maximal_square.nim) |
| Odin | [odin/m/maximal_square.odin](../../../odin/m/maximal_square.odin) |
| Rust | [rust/m/maximal_square.rs](../../../rust/m/maximal_square.rs) |
| V | [v/m/maximal_square.v](../../../v/m/maximal_square.v) |
| Zig | [zig/m/maximal_square.zig](../../../zig/m/maximal_square.zig) |

The package uses the `i64_array_scalar` benchmark ABI.
