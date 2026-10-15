# Validate Sudoku board

Validate a supplied 9×9 Sudoku board without trying to solve it. Filled digits may not repeat in any row, column, or 3×3 box. A valid-but-unsolvable partial board still returns true, matching the pinned Python implementation.

## Contract

The byte-output ABI accepts exactly 81 signed 64-bit ASCII values in row-major order. The accepted symbols are `.` for an empty cell and `1` through `9` for a filled cell. This restricts the general Python string API to the documented Sudoku alphabet; malformed length or another symbol returns `-1` and no output.

The output is one byte: `1` for a board without duplicate filled digits and `0` for a conflicting board. Success returns 1. A null or undersized output buffer returns `-2` before validation results are written.

The source checks shape first, ignores empty cells, and checks membership in the row, column, and box sets. The ports use equivalent 9-bit masks for those three sets. They do not test solvability.

## Pinned source

- Python [`matrix/validate_sudoku_board.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/validate_sudoku_board.py) at `e1a2a8b016001309a73d5fec4818c35cca139795`

## Workload

[`workload.json`](workload.json) includes the pinned valid-board example, valid-but-unsolvable and empty boards, row/column/box conflicts, malformed symbols and lengths, and output-capacity handling.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/v/validate_sudoku_board.c`](../../../c/v/validate_sudoku_board.c) |
| C3 | [`c3/v/validate_sudoku_board.c3`](../../../c3/v/validate_sudoku_board.c3) |
| C++ | [`cpp/v/validate_sudoku_board.cpp`](../../../cpp/v/validate_sudoku_board.cpp) |
| Elisa | [`elisa/v/validate_sudoku_board.elisa`](../../../elisa/v/validate_sudoku_board.elisa) |
| Nim | [`nim/v/validate_sudoku_board.nim`](../../../nim/v/validate_sudoku_board.nim) |
| Odin | [`odin/v/validate_sudoku_board.odin`](../../../odin/v/validate_sudoku_board.odin) |
| Rust | [`rust/v/validate_sudoku_board.rs`](../../../rust/v/validate_sudoku_board.rs) |
| V | [`v/v/validate_sudoku_board.v`](../../../v/v/validate_sudoku_board.v) |
| Zig | [`zig/v/validate_sudoku_board.zig`](../../../zig/v/validate_sudoku_board.zig) |
