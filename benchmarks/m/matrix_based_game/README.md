# Matrix-based game

Run a bounded connected-component removal game on a square board and return the cumulative score from the pinned Python source's process_game behavior.

## Contract

- Input is the signed-i64 vector [n, row-major ASCII cells..., move_count, x0, y0, ...]. The exact length is 2 + n*n + 2*move_count.
- The board dimension n is in 1..8. Initial cells are ASCII codes for A-Z, a-z, or 0-9, matching a portable subset of the source's alphanumeric symbols.
- The move count is in 0..64. Each coordinate is in 0..n-1. Coordinates use the source mapping: (x,y) selects board row n-1-y, column x, with (0,0) at the lower-left.
- Each move removes the 4-connected component of the selected nonempty symbol. Empty selections score zero. After a removal, symbols fall toward the bottom and empty columns compact left, preserving the source's board update behavior.
- A removed component of size k adds k*(k+1)/2. Return the total score in 0..2080. Invalid dimensions, length, symbols, move count, or coordinates return -1.
- The command-line prompts, printing, and input parsing are excluded; the benchmark covers the deterministic process_game operation.

The independent oracle is benchmarks/matrix_based_game_oracle.py. workload.json covers lower-left coordinates, connected components, gravity, empty-column compaction, no-op moves, and invalid input.

Pinned source: [TheAlgorithms/Python matrix_based_game.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/matrix_based_game.py), commit e1a2a8b016001309a73d5fec4818c35cca139795.

Build and run with the i64_array_scalar ABI:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm matrix_based_game --language c
    python3 benchmarks/run_i64_array_scalar.py --algorithm matrix_based_game

| Language | Port |
| --- | --- |
| C | [matrix_based_game.c](../../../c/m/matrix_based_game.c) |
| C3 | [matrix_based_game.c3](../../../c3/m/matrix_based_game.c3) |
| C++ | [matrix_based_game.cpp](../../../cpp/m/matrix_based_game.cpp) |
| Elisa | [matrix_based_game.elisa](../../../elisa/m/matrix_based_game.elisa) |
| Nim | [matrix_based_game.nim](../../../nim/m/matrix_based_game.nim) |
| Odin | [matrix_based_game.odin](../../../odin/m/matrix_based_game.odin) |
| Rust | [matrix_based_game.rs](../../../rust/m/matrix_based_game.rs) |
| V | [matrix_based_game.v](../../../v/m/matrix_based_game.v) |
| Zig | [matrix_based_game.zig](../../../zig/m/matrix_based_game.zig) |
