# L-Tromino Board Tiling

This benchmark ports the pinned Java divide-and-conquer algorithm for a `2^n × 2^n` board with one missing cell. Each recursive call places one L-shaped tromino at the center, then visits quadrants in top-left, top-right, bottom-left, bottom-right order. The missing cell is labeled zero; each placed tromino receives the next positive label.

## Contract

Input is `[board_size, missing_row, missing_column]` in the `i64_array_bytes_output` ABI. `board_size` is a power of two from 1 through 16, and coordinates are zero-based and in range. Invalid input returns `-1`; insufficient output capacity returns `-2`.

Output is the row-major board as signed 32-bit little-endian labels. Success returns the byte count (`board_size² * 4`). The adapter resets the source's static tile counter to one for every call so repeated invocations are deterministic; the recursive tiling and quadrant traversal remain source-matched.

## Workload and source

[`workload.json`](workload.json) covers the base case, a 2×2 board, a larger board, and invalid dimensions/coordinates. The runtime oracle is [`benchmarks/tiling_problem_oracle.py`](../../tiling_problem_oracle.py).

Pinned source: [TheAlgorithms/Java `TilingProblem.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/divideandconquer/TilingProblem.java).

| Language | Port |
|---|---|
| C | [`c/t/tiling_problem.c`](../../../c/t/tiling_problem.c) |
| C3 | [`c3/t/tiling_problem.c3`](../../../c3/t/tiling_problem.c3) |
| C++ | [`cpp/t/tiling_problem.cpp`](../../../cpp/t/tiling_problem.cpp) |
| Elisa | [`elisa/t/tiling_problem.elisa`](../../../elisa/t/tiling_problem.elisa) |
| Nim | [`nim/t/tiling_problem.nim`](../../../nim/t/tiling_problem.nim) |
| Odin | [`odin/t/tiling_problem.odin`](../../../odin/t/tiling_problem.odin) |
| Rust | [`rust/t/tiling_problem.rs`](../../../rust/t/tiling_problem.rs) |
| V | [`v/t/tiling_problem.v`](../../../v/t/tiling_problem.v) |
| Zig | [`zig/t/tiling_problem.zig`](../../../zig/t/tiling_problem.zig) |
