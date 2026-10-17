# Strassen Matrix Multiplication

Multiply two bounded square matrices with the seven-product Strassen recurrence.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, A[n*n], B[n*n]]`, with both matrices in row-major order and exact length `1 + 2*n*n`.
- The supported dimensions are `n ∈ {1, 2, 4, 8}`. Every matrix entry must be in `[-2, 2]`; invalid dimensions, framing, or entries return `-1` before checking output storage.
- Return `C = A × B` in row-major order as `n*n` little-endian signed i64 values (`8*n*n` bytes).
- Null output or insufficient output capacity returns `-2` without writes. The largest output is 512 bytes.
- `n=1` is the scalar multiplication base case. Larger dimensions use the standard Strassen seven-product recurrence. Values are bounded so all intermediate sums and products fit signed i64.

The independent [oracle](../../strassen_matrix_multiplication_oracle.py) uses the conventional triple-loop matrix product, not Strassen recursion.

## Workload

[`workload.json`](workload.json) includes each supported dimension, mixed-sign multiplication, null and short buffers, and invalid dimensions, entries, and framing.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/strassen_matrix_multiplication.c`](../../../c/s/strassen_matrix_multiplication.c) |
| C3 | [`c3/s/strassen_matrix_multiplication.c3`](../../../c3/s/strassen_matrix_multiplication.c3) |
| C++ | [`cpp/s/strassen_matrix_multiplication.cpp`](../../../cpp/s/strassen_matrix_multiplication.cpp) |
| Elisa | [`elisa/s/strassen_matrix_multiplication.elisa`](../../../elisa/s/strassen_matrix_multiplication.elisa) |
| Nim | [`nim/s/strassen_matrix_multiplication.nim`](../../../nim/s/strassen_matrix_multiplication.nim) |
| Odin | [`odin/s/strassen_matrix_multiplication.odin`](../../../odin/s/strassen_matrix_multiplication.odin) |
| Rust | [`rust/s/strassen_matrix_multiplication.rs`](../../../rust/s/strassen_matrix_multiplication.rs) |
| V | [`v/s/strassen_matrix_multiplication.v`](../../../v/s/strassen_matrix_multiplication.v) |
| Zig | [`zig/s/strassen_matrix_multiplication.zig`](../../../zig/s/strassen_matrix_multiplication.zig) |

## Pinned sources

- Go [`strassenmatrixmultiply.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/strassenmatrixmultiply.go) at `5ba447ec5ff3d1213de65b92e726ee74c5d5cc19`.
- Java [`StrassenMatrixMultiplication.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/divideandconquer/StrassenMatrixMultiplication.java) at `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

The selected Go and Java implementations use Strassen for these dimensions. The C++ copies use a naive path at these sizes, and the Python wrapper does not perform multiplication; neither is part of this benchmark contract.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm strassen_matrix_multiplication --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm strassen_matrix_multiplication
```
