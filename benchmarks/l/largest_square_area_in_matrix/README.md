# Largest square in a binary matrix

The pinned Python file provides four variants: exponential recursion, memoized recursion, bottom-up DP, and bottom-up space optimization. All return the maximum all-1 square's side length, despite the function and candidate name saying area. This package follows the bottom-up recurrence from bottom right to top left.

## Contract

Input is `[rows, cols, row_major_cells...]` for dimensions 1 through 8 and cell values 0 or 1. Output is the side length; malformed inputs return -2.

See [workload](workload.json), [independent oracle](../../largest_square_area_in_matrix_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/largest_square_area_in_matrix.py).

| Language | Port |
|---|---|
| C | [`c/l/largest_square_area_in_matrix.c`](../../../c/l/largest_square_area_in_matrix.c) |
| C3 | [`c3/l/largest_square_area_in_matrix.c3`](../../../c3/l/largest_square_area_in_matrix.c3) |
| C++ | [`cpp/l/largest_square_area_in_matrix.cpp`](../../../cpp/l/largest_square_area_in_matrix.cpp) |
| Elisa | [`elisa/l/largest_square_area_in_matrix.elisa`](../../../elisa/l/largest_square_area_in_matrix.elisa) |
| Nim | [`nim/l/largest_square_area_in_matrix.nim`](../../../nim/l/largest_square_area_in_matrix.nim) |
| Odin | [`odin/l/largest_square_area_in_matrix.odin`](../../../odin/l/largest_square_area_in_matrix.odin) |
| Rust | [`rust/l/largest_square_area_in_matrix.rs`](../../../rust/l/largest_square_area_in_matrix.rs) |
| V | [`v/l/largest_square_area_in_matrix.v`](../../../v/l/largest_square_area_in_matrix.v) |
| Zig | [`zig/l/largest_square_area_in_matrix.zig`](../../../zig/l/largest_square_area_in_matrix.zig) |
