# Matrix rank

Compute the rank of a bounded row-major matrix using the pivot scan and Gaussian elimination from the pinned Java source.

## Contract

- Input is the signed-i64 vector [rows, cols, cell_0, ..., cell_(rows*cols-1)], with row-major cells and exact length 2 + rows*cols.
- Both dimensions are in 1..8. Each cell is exactly 0 or 1.
- Return the integer matrix rank. Invalid length, shape, or cell values return -1. The input is read only.
- The implementation copies cells to binary64, scans columns left-to-right, selects the first unmarked row whose pivot magnitude is at least 1e-10, normalizes only entries to the right of the pivot, and eliminates that column from every other row. It preserves the source's EPSILON = 1e-10 rule and first-eligible-pivot order.
- The binary domain and small dimensions avoid near-singular threshold ambiguity while retaining rectangular matrices.

The independent exact-arithmetic oracle is benchmarks/matrix_rank_oracle.py. workload.json covers zero, dependent, rectangular, pivot-skip, full-rank, and malformed cases.

Pinned source: [TheAlgorithms/Java MatrixRank.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/MatrixRank.java), commit e43ec3897e48f23843972d02cd05a5bb1b6864a2.

Build and run with the i64_array_scalar ABI:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm matrix_rank --language c
    python3 benchmarks/run_i64_array_scalar.py --algorithm matrix_rank

| Language | Port |
| --- | --- |
| C | [matrix_rank.c](../../../c/m/matrix_rank.c) |
| C3 | [matrix_rank.c3](../../../c3/m/matrix_rank.c3) |
| C++ | [matrix_rank.cpp](../../../cpp/m/matrix_rank.cpp) |
| Elisa | [matrix_rank.elisa](../../../elisa/m/matrix_rank.elisa) |
| Nim | [matrix_rank.nim](../../../nim/m/matrix_rank.nim) |
| Odin | [matrix_rank.odin](../../../odin/m/matrix_rank.odin) |
| Rust | [matrix_rank.rs](../../../rust/m/matrix_rank.rs) |
| V | [matrix_rank.v](../../../v/m/matrix_rank.v) |
| Zig | [matrix_rank.zig](../../../zig/m/matrix_rank.zig) |
