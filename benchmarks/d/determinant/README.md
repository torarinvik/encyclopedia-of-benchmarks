# Determinant

Compute the exact determinant of a small square integer matrix by recursive cofactor expansion.

## Pinned sources

- Go [`determinant.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/determinant.go) expands across the first row.
- JavaScript [`Determinant.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Determinant.js) uses Laplace expansion and alternating cofactor signs.
- Julia [`determinant.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/matrix/determinant.jl) uses LU decomposition and multiplies the diagonal entries.

The Go snapshot adds both even and odd column cofactors. This benchmark follows the determinant definition and applies the alternating sign for odd columns, matching the JavaScript source’s cofactor rule. Julia uses unpivoted LU; matrices that require a row pivot (including the row-swap fixture) or are singular can diverge from this exact integer contract.

## Contract

Input is a signed 64-bit array `[dimension, row-major matrix entries...]`. The dimension is 1 through 6 and every entry is an integer from -9 through 9. The input length must be exactly `1 + dimension * dimension` and is at most 37 values.

The output is the exact signed 64-bit determinant. The entry and dimension bounds keep every valid result in range; invalid input returns `INT64_MIN`, which cannot be a valid determinant in this domain.

The recursive cofactor expansion has factorial time complexity. The small matrix bound keeps its work finite and bounded across all nine ports.

## Workload

[`workload.json`](workload.json) covers one-by-one matrices, sign changes, singular matrices, triangular matrices, the JavaScript source example, the maximum dimension, and malformed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/determinant.c`](../../../c/d/determinant.c) |
| C3 | [`c3/d/determinant.c3`](../../../c3/d/determinant.c3) |
| C++ | [`cpp/d/determinant.cpp`](../../../cpp/d/determinant.cpp) |
| Elisa | [`elisa/d/determinant.elisa`](../../../elisa/d/determinant.elisa) |
| Nim | [`nim/d/determinant.nim`](../../../nim/d/determinant.nim) |
| Odin | [`odin/d/determinant.odin`](../../../odin/d/determinant.odin) |
| Rust | [`rust/d/determinant.rs`](../../../rust/d/determinant.rs) |
| V | [`v/d/determinant.v`](../../../v/d/determinant.v) |
| Zig | [`zig/d/determinant.zig`](../../../zig/d/determinant.zig) |
