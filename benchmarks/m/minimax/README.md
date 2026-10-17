# Minimax on a full binary tree

## Contract

This benchmark evaluates the full binary leaf-score tree used by the pinned C++ `minimax` source. Input is `[leaf_count, first_turn_is_max, leaf_scores...]`, with a power-of-two leaf count from 1 to 32, a turn flag of 1 for maximizing or 0 for minimizing, and signed 32-bit leaf scores. Evaluation begins at depth and node index zero, alternates max/min at each level, and returns the root score. A single leaf returns its score directly.

Malformed input or out-of-range values returns `-2147483649`, which is outside the signed 32-bit score range. The equivalent Java `MiniMaxAlgorithm` and Python leaf-array variants use the same recurrence. Swift's tic-tac-toe minimax is a different game-state API and is outside this contract.

## Workload

[`workload.json`](workload.json) covers one-leaf trees, both root turn types, alternating levels, valid score `-1`, signed 32-bit extrema, the 32-leaf boundary, malformed counts, and invalid values.

## TheAlgorithms references

- C++ [`backtracking/minimax.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/backtracking/minimax.cpp) recursively evaluates the complete tree with `std::max` and `std::min`.
- Java [`MiniMaxAlgorithm`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/MiniMaxAlgorithm.java) evaluates a power-of-two score array and alternates the maximizing player with the minimizing player.
- Python [`minimax.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/minimax.py) uses the same full-tree recurrence.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/minimax.c](../../../c/m/minimax.c) |
| C3 | [c3/m/minimax.c3](../../../c3/m/minimax.c3) |
| C++ | [cpp/m/minimax.cpp](../../../cpp/m/minimax.cpp) |
| Elisa | [elisa/m/minimax.elisa](../../../elisa/m/minimax.elisa) |
| Nim | [nim/m/minimax.nim](../../../nim/m/minimax.nim) |
| Odin | [odin/m/minimax.odin](../../../odin/m/minimax.odin) |
| Rust | [rust/m/minimax.rs](../../../rust/m/minimax.rs) |
| V | [v/m/minimax.v](../../../v/m/minimax.v) |
| Zig | [zig/m/minimax.zig](../../../zig/m/minimax.zig) |
