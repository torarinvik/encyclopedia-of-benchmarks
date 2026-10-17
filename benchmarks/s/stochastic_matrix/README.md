# Stochastic Matrix

Check every row or every column of a bounded rectangular matrix for stochasticity, using the pinned Java source's fixed tolerance.

## Contract

- The `i64_array_scalar` ABI accepts `[mode, rows, columns, row-major cell_units...]`. Mode `0` checks whether every row passes; mode `1` checks whether every column passes. Rows and columns are each in `1..63`, and the array must contain exactly `3 + rows * columns` signed 64-bit values.
- Each cell is encoded as a fixed-point integer in `[-1,000,000,000,000, 1,000,000,000,000]` and converted to binary64 as `cell_units / 1e12`. This represents finite values in `[-1, 1]`; a negative entry makes the mode's predicate false. The maximum input has 3,972 values, below the ABI's 4,096-value cap.
- A row or column passes when it contains no negative entries and `abs(sum - 1.0) <= 1e-9`. Sums use binary64 additions in the source order: left-to-right for each row and top-to-bottom for each column. The result is `1` when every row or every column passes, according to the mode, and `0` otherwise. Invalid mode, dimensions, length, or cell units return `-1`.
- The rectangular, finite fixed-point domain is a bounded subset of the source's `double[][]` input. It avoids the source's inconsistent behavior on ragged rows and excludes NaN and infinity.

The package follows [`StochasticMatrix.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/StochasticMatrix.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. See the [workload](workload.json) and [oracle](../../stochastic_matrix_oracle.py).

| Language | Port |
|---|---|
| C | [stochastic_matrix.c](../../../c/s/stochastic_matrix.c) |
| C3 | [stochastic_matrix.c3](../../../c3/s/stochastic_matrix.c3) |
| C++ | [stochastic_matrix.cpp](../../../cpp/s/stochastic_matrix.cpp) |
| Elisa | [stochastic_matrix.elisa](../../../elisa/s/stochastic_matrix.elisa) |
| Nim | [stochastic_matrix.nim](../../../nim/s/stochastic_matrix.nim) |
| Odin | [stochastic_matrix.odin](../../../odin/s/stochastic_matrix.odin) |
| Rust | [stochastic_matrix.rs](../../../rust/s/stochastic_matrix.rs) |
| V | [stochastic_matrix.v](../../../v/s/stochastic_matrix.v) |
| Zig | [stochastic_matrix.zig](../../../zig/s/stochastic_matrix.zig) |
