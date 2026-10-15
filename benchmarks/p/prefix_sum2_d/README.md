# Two-dimensional prefix sum

This package follows the pinned Java [`PrefixSum2D`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/prefixsum/PrefixSum2D.java). It builds a padded summed-area table, then answers one inclusive rectangular sum query.

## Contract

The `i64_array_scalar` input is `[rows, cols, matrix entries in row-major order, row1, col1, row2, col2]`. Dimensions range from 1 through 16, each matrix entry is an integer in `[-1000,1000]`, and query coordinates are zero-based and inclusive with `row1 <= row2` and `col1 <= col2` inside the matrix.

The source recurrence is preserved in order: `P[i+1][j+1] = matrix[i][j] + P[i][j+1] + P[i+1][j] - P[i][j]`. The result uses the source's inclusion-exclusion order: `P[row2+1][col2+1] - P[row1][col2+1] - P[row2+1][col1] + P[row1][col1]`. It returns a signed 64-bit sum. Invalid dimensions, packing, values, or query bounds return `INT64_MIN` (`-9223372036854775808`), which cannot collide with a valid result in this bounded domain.

This is a two-dimensional summed-area table operation, distinct from one-dimensional prefix sums and range-sum queries. Runtime and auxiliary space are O(rows × cols).

## Workload and recording

[`workload.json`](workload.json) covers full and partial rectangles, a valid result of `-1`, negative cells, and malformed queries. Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm prefix_sum2_d --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm prefix_sum2_d
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/prefix_sum2_d.c`](../../../c/p/prefix_sum2_d.c) |
| C3 | [`c3/p/prefix_sum2_d.c3`](../../../c3/p/prefix_sum2_d.c3) |
| C++ | [`cpp/p/prefix_sum2_d.cpp`](../../../cpp/p/prefix_sum2_d.cpp) |
| Elisa | [`elisa/p/prefix_sum2_d.elisa`](../../../elisa/p/prefix_sum2_d.elisa) |
| Nim | [`nim/p/prefix_sum2_d.nim`](../../../nim/p/prefix_sum2_d.nim) |
| Odin | [`odin/p/prefix_sum2_d.odin`](../../../odin/p/prefix_sum2_d.odin) |
| Rust | [`rust/p/prefix_sum2_d.rs`](../../../rust/p/prefix_sum2_d.rs) |
| V | [`v/p/prefix_sum2_d.v`](../../../v/p/prefix_sum2_d.v) |
| Zig | [`zig/p/prefix_sum2_d.zig`](../../../zig/p/prefix_sum2_d.zig) |

## Pinned source

- Java [`PrefixSum2D.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/prefixsum/PrefixSum2D.java)
