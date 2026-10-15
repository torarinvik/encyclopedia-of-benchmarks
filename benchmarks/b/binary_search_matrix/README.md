# Binary search matrix

This benchmark follows the pinned Python `mat_bin_search` implementation. It scans the rows in order and calls its recursive binary search on each row whose first value is less than the target.

## Contract

- The array ABI encodes `[row_count, column_count, target, row-major matrix values...]`.
- Matrices are nonempty, rectangular, and sorted in the order expected by the source: values in each row are nondecreasing and row-first values are nondecreasing.
- Dimensions are at most 32 by 32, and values and target are in `[-1,000,000,000, 1,000,000,000]`.
- A found coordinate `[row, column]` is encoded as `row * column_count + column`. Missing values and invalid shapes return `-1`.
- The source's later-row first-column edge case is preserved: if the target equals the first value of a row after row zero, the outer loop stops before searching that row and reports `-1`. The first matrix element is checked separately and returns coordinate `[0, 0]`.

[`workload.json`](workload.json) includes the source's documented example, found and missing values, the first-column edge case, a one-cell matrix, and empty input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_search_matrix.c`](../../../c/b/binary_search_matrix.c) |
| C3 | [`c3/b/binary_search_matrix.c3`](../../../c3/b/binary_search_matrix.c3) |
| C++ | [`cpp/b/binary_search_matrix.cpp`](../../../cpp/b/binary_search_matrix.cpp) |
| Elisa | [`elisa/b/binary_search_matrix.elisa`](../../../elisa/b/binary_search_matrix.elisa) |
| Nim | [`nim/b/binary_search_matrix.nim`](../../../nim/b/binary_search_matrix.nim) |
| Odin | [`odin/b/binary_search_matrix.odin`](../../../odin/b/binary_search_matrix.odin) |
| Rust | [`rust/b/binary_search_matrix.rs`](../../../rust/b/binary_search_matrix.rs) |
| V | [`v/b/binary_search_matrix.v`](../../../v/b/binary_search_matrix.v) |
| Zig | [`zig/b/binary_search_matrix.zig`](../../../zig/b/binary_search_matrix.zig) |

## Upstream source

- [TheAlgorithms/Python `binary_search_matrix.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/binary_search_matrix.py)
