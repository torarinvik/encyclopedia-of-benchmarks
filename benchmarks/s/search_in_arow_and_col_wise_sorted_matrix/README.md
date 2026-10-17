# Search in a Row and Column Wise Sorted Matrix

Search a square matrix whose rows and columns are sorted in nondecreasing order, following the pinned Java upper-right staircase walk.

## Contract

- The `i64_array_bytes_output` ABI accepts `[n, target, row-major cells...]`, with `1 <= n <= 63`, exactly `2 + n*n` signed 64-bit input values, and signed 32-bit target and cell values.
- Every row and column must be nondecreasing, and the target may occur at most once. Invalid framing, values, ordering, or duplicate-target input returns `-1` without writing.
- A valid hit returns `1`; a valid miss returns `0`. Both cases write exactly two little-endian signed 32-bit values to the output buffer: the zero-based `[row, column]` on a hit, or `[-1, -1]` on a miss. The maximum output is 8 bytes. Null output or capacity below 8 returns `-2` without writing.
- The search starts at `(0,n-1)`, moves down when `target > cell`, and moves left otherwise, matching the pinned source. The unique-target restriction makes returned coordinates unambiguous across ports.

The source is pinned to [`SearchInARowAndColWiseSortedMatrix.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/SearchInARowAndColWiseSortedMatrix.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. See the [workload](workload.json) and [oracle](../../search_in_arow_and_col_wise_sorted_matrix_oracle.py).

| Language | Port |
|---|---|
| C | [search_in_arow_and_col_wise_sorted_matrix.c](../../../c/s/search_in_arow_and_col_wise_sorted_matrix.c) |
| C3 | [search_in_arow_and_col_wise_sorted_matrix.c3](../../../c3/s/search_in_arow_and_col_wise_sorted_matrix.c3) |
| C++ | [search_in_arow_and_col_wise_sorted_matrix.cpp](../../../cpp/s/search_in_arow_and_col_wise_sorted_matrix.cpp) |
| Elisa | [search_in_arow_and_col_wise_sorted_matrix.elisa](../../../elisa/s/search_in_arow_and_col_wise_sorted_matrix.elisa) |
| Nim | [search_in_arow_and_col_wise_sorted_matrix.nim](../../../nim/s/search_in_arow_and_col_wise_sorted_matrix.nim) |
| Odin | [search_in_arow_and_col_wise_sorted_matrix.odin](../../../odin/s/search_in_arow_and_col_wise_sorted_matrix.odin) |
| Rust | [search_in_arow_and_col_wise_sorted_matrix.rs](../../../rust/s/search_in_arow_and_col_wise_sorted_matrix.rs) |
| V | [search_in_arow_and_col_wise_sorted_matrix.v](../../../v/s/search_in_arow_and_col_wise_sorted_matrix.v) |
| Zig | [search_in_arow_and_col_wise_sorted_matrix.zig](../../../zig/s/search_in_arow_and_col_wise_sorted_matrix.zig) |
