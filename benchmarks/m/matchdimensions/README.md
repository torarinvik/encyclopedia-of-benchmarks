# Match dimensions

## Contract

This benchmark preserves the pinned Go `MatchDimensions` behavior: return true exactly when two matrices have the same row count and the same column count. The `i64_array_scalar` ABI supplies `[rows_a, columns_a, rows_b, columns_b]`. Each dimension must be in `0..=65535`; a null input pointer, malformed length, or out-of-range dimension returns `-1`, otherwise the result is `1` for equal dimensions and `0` for unequal dimensions.

Zero-sized dimensions are valid. The comparison does not inspect matrix elements because the source operation compares only the stored dimensions.

## Workload

[`workload.json`](workload.json) covers equal and unequal shapes, zero dimensions, the upper bound, invalid dimensions, and malformed input lengths.

## TheAlgorithms reference

- Go [`MatchDimensions`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/matchdimensions.go) compares the row and column counts of the two matrices.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/matchdimensions.c](../../../c/m/matchdimensions.c) |
| C3 | [c3/m/matchdimensions.c3](../../../c3/m/matchdimensions.c3) |
| C++ | [cpp/m/matchdimensions.cpp](../../../cpp/m/matchdimensions.cpp) |
| Elisa | [elisa/m/matchdimensions.elisa](../../../elisa/m/matchdimensions.elisa) |
| Nim | [nim/m/matchdimensions.nim](../../../nim/m/matchdimensions.nim) |
| Odin | [odin/m/matchdimensions.odin](../../../odin/m/matchdimensions.odin) |
| Rust | [rust/m/matchdimensions.rs](../../../rust/m/matchdimensions.rs) |
| V | [v/m/matchdimensions.v](../../../v/m/matchdimensions.v) |
| Zig | [zig/m/matchdimensions.zig](../../../zig/m/matchdimensions.zig) |
