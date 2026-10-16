# N-in-a-row board status

This benchmark ports the win/draw/continue check in the pinned Swift [Minimax `Board`](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/algorithms/AI/minimax/Sources/Minimax.playground/Sources/Model/Board/Board.swift).

## Input and output

The signed 64-bit input is `[size, player, cell...]`, followed by `size × size` row-major cells. Board sizes are 2..16. `player` and cells use 1 for the player being checked, 2 for the opponent, and 0 for an empty cell.

The result is 1 for a full row, column, or main diagonal containing the selected player; otherwise it is 0 if any cell is empty and 2 for a full-board draw. The selected player’s win takes priority over empty cells, matching `Board.check`. Invalid dimensions, player values, cell values, or array lengths return -1.

The Swift class also exposes board mutation and position lookup; those helpers are outside this status-check contract. The source’s size-one board reports a win without a matching cell, so the shared contract begins at size two. The ports check the two possible full-length diagonals directly, which has the same result as the source’s diagonal-start scans.

## Workloads

Cases cover row, column, both diagonal directions, opponent-only lines, wins on a board with empty cells, full-board draws, a maximum-size board, malformed input, and invalid cell/player values.

Verify the nine ports against the independent oracle with `python3 benchmarks/verify_i64_array_scalar.py --algorithms n_in_a_row_board_status`.
