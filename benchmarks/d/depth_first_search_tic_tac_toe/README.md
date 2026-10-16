# Tic-tac-toe minimax search

The pinned Rust source is a deterministic recursive minimax search for the next move on a 3×3 tic-tac-toe board. It is distinct from [`n_in_a_row_board_status`](../../n/n_in_a_row_board_status/README.md), which only classifies a board; it also differs from graph DFS benchmarks because it searches alternating game states and ranks outcomes.

## Contract

Input is exactly ten signed 64-bit integers: `[side, cell0, ..., cell8]`. Cells are row-major and use `0` for blank, `1` for X, and `2` for O. `side` is the player to move (1 or 2). The contract accepts all cell assignments, including unreachable game positions, as the pinned public `minimax` routine does. Invalid length, side, or cell values return `-1`.

A terminal board (either player already has a line, or no empty cells remain) returns `0`, matching the source's `None`. Otherwise the result is `1 + 512*score + move_mask`. `score` is `0` for a draw, `1` for X, or `2` for O. Bit `i` in the low nine bits marks row-major move `i`; every equally best move is included. At each recursive step the source prefers a win for the player to move, then a draw, then a loss. Move ordering is row-major, as in `available_positions`.

[`workload.json`](workload.json) covers immediate wins, blocking/fork positions, terminal states, and invalid inputs. The independent oracle is [`depth_first_search_tic_tac_toe_oracle.py`](../../depth_first_search_tic_tac_toe_oracle.py). The verifier exhaustively checks both sides for all 3^9 board assignments.

## Ports

| Language | Source |
|---|---|
| C | [`c/d/depth_first_search_tic_tac_toe.c`](../../../c/d/depth_first_search_tic_tac_toe.c) |
| C3 | [`c3/d/depth_first_search_tic_tac_toe.c3`](../../../c3/d/depth_first_search_tic_tac_toe.c3) |
| C++ | [`cpp/d/depth_first_search_tic_tac_toe.cpp`](../../../cpp/d/depth_first_search_tic_tac_toe.cpp) |
| Elisa | [`elisa/d/depth_first_search_tic_tac_toe.elisa`](../../../elisa/d/depth_first_search_tic_tac_toe.elisa) |
| Nim | [`nim/d/depth_first_search_tic_tac_toe.nim`](../../../nim/d/depth_first_search_tic_tac_toe.nim) |
| Odin | [`odin/d/depth_first_search_tic_tac_toe.odin`](../../../odin/d/depth_first_search_tic_tac_toe.odin) |
| Rust | [`rust/d/depth_first_search_tic_tac_toe.rs`](../../../rust/d/depth_first_search_tic_tac_toe.rs) |
| V | [`v/d/depth_first_search_tic_tac_toe.v`](../../../v/d/depth_first_search_tic_tac_toe.v) |
| Zig | [`zig/d/depth_first_search_tic_tac_toe.zig`](../../../zig/d/depth_first_search_tic_tac_toe.zig) |

Run `python3 benchmarks/verify_i64_array_scalar.py --algorithms depth_first_search_tic_tac_toe` to verify the ports and workload records.
