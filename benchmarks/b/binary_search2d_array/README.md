# Binary search in a 2D array

Search a sorted matrix by narrowing rows using the middle column, then binary-searching one row slice. This follows the pinned Java `BinarySearch2dArray` method on a bounded matrix domain.

## Contract

- The `i64_array_scalar` ABI receives `[rows, columns, target, matrix...]`, with the matrix in row-major order.
- The bounded domain has 2 through 32 rows and 3 through 32 columns. Values and target fit signed 32-bit integers.
- Every row and column is strictly increasing. The target may be present or absent.
- Return the row-major index `row * columns + column` when found, or `-1` when absent. Invalid dimensions or a packed input length mismatch return `-1`.
- The Java source returns `[row, column]`; the benchmark encodes that coordinate as one row-major index. The matrix is not modified by the benchmark ports.

The minimum dimensions normalize the source method's special one-row path and avoid its unchecked middle-column neighbors for narrow matrices. Sortedness is an input precondition.

## Source

This follows the pinned [TheAlgorithms Java `BinarySearch2dArray.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/BinarySearch2dArray.java). The method binary-searches the middle column to reduce the candidate rows, then searches the appropriate half of one of those rows.

## Workload

[`workload.json`](workload.json) covers the smallest supported matrix, middle-column hits, left and right row slices, absent targets, and malformed dimensions and packing.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_search2d_array.c`](../../../c/b/binary_search2d_array.c) |
| C3 | [`c3/b/binary_search2d_array.c3`](../../../c3/b/binary_search2d_array.c3) |
| C++ | [`cpp/b/binary_search2d_array.cpp`](../../../cpp/b/binary_search2d_array.cpp) |
| Elisa | [`elisa/b/binary_search2d_array.elisa`](../../../elisa/b/binary_search2d_array.elisa) |
| Nim | [`nim/b/binary_search2d_array.nim`](../../../nim/b/binary_search2d_array.nim) |
| Odin | [`odin/b/binary_search2d_array.odin`](../../../odin/b/binary_search2d_array.odin) |
| Rust | [`rust/b/binary_search2d_array.rs`](../../../rust/b/binary_search2d_array.rs) |
| V | [`v/b/binary_search2d_array.v`](../../../v/b/binary_search2d_array.v) |
| Zig | [`zig/b/binary_search2d_array.zig`](../../../zig/b/binary_search2d_array.zig) |

