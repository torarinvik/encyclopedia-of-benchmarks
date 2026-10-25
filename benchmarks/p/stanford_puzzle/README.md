# Stanford Puzzle 3D packing search

This package preserves the deterministic search core of the Stanford Puzzle benchmark attributed in its pinned source to Forest Baskett. It tiles a 5×5×5 box with fixed orientations of 18 pieces. The search always selects the first empty cell, tries the 13 piece orientations in source order, observes shared counts for the four piece classes, and stops at the first complete packing. The source repeats the same puzzle 100 times; the bounded function accepts 1–100 repetitions.

## Contract

The `i64_array_scalar` function is `stanford_puzzle`. Its input is the one-element array `[passes]`, where `passes` is from 1 through 100. Each pass starts from an empty 5×5×5 board, places the first 4×2×1 piece at the origin, then runs the fixed DFS. The piece shapes are the six 8-cell rectangular orientations `(4,2,1)`, `(2,1,4)`, `(1,4,2)`, `(2,4,1)`, `(4,1,2)`, `(1,2,4)`; three 3-cell rods; three 4-cell 2×2 plates; and one 2×2×2 block. The remaining class counts are `[13,3,1,1]` before the initial piece is placed.

The returned scalar sums one packed observation per pass: `source_first_empty_index * 1,000,000 + recursive_call_count`. The first empty cell after the initial placement is source index 77. The pinned program asserts that the DFS makes 2,005 calls. Invalid input or exceeding the 2,005-call safety bound returns `-1`.

This is a 3D fixed-piece packing search. It is distinct from the local BenchmarkGame puzzle's shuffle/XOR workload, the 2D L-tromino divide-and-conquer tiler, 2×n domino counting, and the general binary-matrix Algorithm X package. It does not implement rotations beyond the 13 source orientations or enumerate all packings.

## Source attribution and rights

Pinned source: [`Stanford/Puzzle/Puzzle.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Puzzle/Puzzle.c) at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher uses `Puzzle.c` with `-lm` and no arguments. The source comments attribute the compute-bound puzzle to Forest Baskett, but the pinned file has no explicit redistribution license or grant. These ports are independent implementations based on the published piece dimensions, search order, and observed source behavior; no upstream code or comments have been copied. The attribution and missing-license status are recorded here and in every language source header.

See [workload.json](workload.json) and the independent [Python oracle](../../stanford_puzzle_oracle.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/stanford_puzzle.c`](../../../c/p/stanford_puzzle.c) |
| C3 | [`c3/p/stanford_puzzle.c3`](../../../c3/p/stanford_puzzle.c3) |
| C++ | [`cpp/p/stanford_puzzle.cpp`](../../../cpp/p/stanford_puzzle.cpp) |
| Elisa | [`elisa/p/stanford_puzzle.elisa`](../../../elisa/p/stanford_puzzle.elisa) |
| Nim | [`nim/p/stanford_puzzle.nim`](../../../nim/p/stanford_puzzle.nim) |
| Odin | [`odin/p/stanford_puzzle.odin`](../../../odin/p/stanford_puzzle.odin) |
| Rust | [`rust/p/stanford_puzzle.rs`](../../../rust/p/stanford_puzzle.rs) |
| V | [`v/p/stanford_puzzle.v`](../../../v/p/stanford_puzzle.v) |
| Zig | [`zig/p/stanford_puzzle.zig`](../../../zig/p/stanford_puzzle.zig) |
