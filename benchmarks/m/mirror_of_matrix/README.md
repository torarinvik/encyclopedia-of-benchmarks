# Mirror of a matrix

This package implements the pinned Java `MirrorOfMatrix.mirrorMatrix` operation as a horizontal reflection: it reverses each row while keeping rows in their original order. It returns a new row-major matrix and does not change the input.

## Contract

The `i64_array_bytes_output` input is `[rows, columns, cell_0, ..., cell_(rows*columns-1)]`, with cells in row-major order. Both dimensions must be 1 through 16, the payload length must be exactly `2 + rows * columns`, and each cell must fit a signed 32-bit integer. Invalid input returns -1. A null output pointer or a buffer too short for all reflected cells returns -2 without writing; valid output contains every cell as a little-endian signed i32 and the return value is its byte count. The maximum matrix is 16 by 16 and the maximum output is 1,024 bytes.

The pinned Java source validates that the input matrix is non-null, nonempty, and rectangular, then creates a new matrix with each row reversed. It preserves values such as NaN and infinity without filtering them. This benchmark deliberately bounds the shape and models integer-valued cells as signed i32 so the result fits the shared byte-output ABI.

Pinned source: [TheAlgorithms/Java `MirrorOfMatrix.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/MirrorOfMatrix.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`, method `MirrorOfMatrix.mirrorMatrix`.

The independent bounded oracle is [mirror_of_matrix_oracle.py](../../mirror_of_matrix_oracle.py); the workload is [workload.json](workload.json).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/mirror_of_matrix.c](../../../c/m/mirror_of_matrix.c) |
| C3 | [c3/m/mirror_of_matrix.c3](../../../c3/m/mirror_of_matrix.c3) |
| C++ | [cpp/m/mirror_of_matrix.cpp](../../../cpp/m/mirror_of_matrix.cpp) |
| Elisa | [elisa/m/mirror_of_matrix.elisa](../../../elisa/m/mirror_of_matrix.elisa) |
| Nim | [nim/m/mirror_of_matrix.nim](../../../nim/m/mirror_of_matrix.nim) |
| Odin | [odin/m/mirror_of_matrix.odin](../../../odin/m/mirror_of_matrix.odin) |
| Rust | [rust/m/mirror_of_matrix.rs](../../../rust/m/mirror_of_matrix.rs) |
| V | [v/m/mirror_of_matrix.v](../../../v/m/mirror_of_matrix.v) |
| Zig | [zig/m/mirror_of_matrix.zig](../../../zig/m/mirror_of_matrix.zig) |

Build a selected port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm mirror_of_matrix --language rust
```

Record with:

```sh
python3 benchmarks/run_i64_array_bytes_output.py --algorithm mirror_of_matrix
```

Verify with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm mirror_of_matrix --languages rust
```
