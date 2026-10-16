# Check equal

Compare two integer matrices for equality. The pinned Go `CheckEqual` first
checks that both dimensions match, then compares the row-major elements and
returns a Boolean result. The benchmark encodes that result as `1` for equal
and `0` for unequal; malformed packed input returns `-1`.

## Contract

- Input is `[rowsA, columnsA, rowsB, columnsB, elementsA..., elementsB...]`.
- Each dimension is in `0..32`; matrix entries are signed 64-bit integers.
- Each matrix's entries are flattened in row-major order. Its entry count must
  equal its own `rows * columns`, even when the dimensions differ.
- Return `1` when both dimensions and every corresponding value match, `0`
  when the shapes or any value differ, and `-1` for invalid dimensions, an
  incomplete header, an out-of-bound input length, or inconsistent payload size.
- Empty shapes retain their dimensions: `0 x 4` equals `0 x 4`, but differs
  from `4 x 0`. The largest valid packed input has 2,052 values. The verifier
  also includes a one-value-over-bound malformed case.

The pinned Go source is generic over integer element types. These ports use the
signed 64-bit subset accepted by the shared array ABI. They preserve the
predicate's result while scanning sequentially; Go's per-row goroutines and
constructor behavior are outside this result-only contract.

## Workload and oracle

[`workload.json`](workload.json) covers equal and unequal scalar and
rectangular matrices, shape mismatches with equal element counts, zero-sized
shapes, malformed headers and dimensions, and the maximum matrix size. The
independent [`checkequal_oracle.py`](../../checkequal_oracle.py) checks the
packed shape before comparing the flattened values.

Verify with `python3 benchmarks/verify_i64_array_scalar.py --algorithms checkequal --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.

## Pinned sources

- [TheAlgorithms/Go `checkequal.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/checkequal.go)
- [TheAlgorithms/Go `matrix.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/matrix.go)
- [TheAlgorithms/Go `matchdimensions.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/matchdimensions.go)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/checkequal.c`](../../../c/c/checkequal.c) |
| C3 | [`c3/c/checkequal.c3`](../../../c3/c/checkequal.c3) |
| C++ | [`cpp/c/checkequal.cpp`](../../../cpp/c/checkequal.cpp) |
| Elisa | [`elisa/c/checkequal.elisa`](../../../elisa/c/checkequal.elisa) |
| Nim | [`nim/c/checkequal.nim`](../../../nim/c/checkequal.nim) |
| Odin | [`odin/c/checkequal.odin`](../../../odin/c/checkequal.odin) |
| Rust | [`rust/c/checkequal.rs`](../../../rust/c/checkequal.rs) |
| V | [`v/c/checkequal.v`](../../../v/c/checkequal.v) |
| Zig | [`zig/c/checkequal.zig`](../../../zig/c/checkequal.zig) |
