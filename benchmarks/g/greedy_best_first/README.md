# Greedy best-first grid search

This benchmark ports the pinned Python `GreedyBestFirst` grid search. It expands the open cell with the smallest Manhattan distance to the goal, preserving insertion order for equal heuristics. It does not add path cost to the priority, so it is distinct from A* search.

## Contract

- Input is `[rows, columns, start_row, start_column, goal_row, goal_column, obstacle_masks...]`, with a rectangular grid of `1..3` rows and columns. A set bit marks an obstacle in its row; coordinates are zero-based.
- Successors are considered up, left, down, right. The open list is stably sorted by Manhattan distance only. A cell already open keeps its first parent; closed cells are never reopened.
- If the goal is unreachable, the source returns a path containing only the start cell. Starting at the goal also returns that one-cell path.
- The signed-64-bit result packs each path cell's one-based row-major index in a four-bit slot, followed by the path length starting at bit 36. The bound of nine cells keeps the complete path representable.
- Invalid dimensions, mismatched row-mask counts, out-of-grid coordinates, obstacle bits outside the grid, or blocked endpoints return `-1`.

The 3×3 bound allows exact path-order comparison in the packed result while retaining the source's stable tie behavior.

## Pinned source

- [TheAlgorithms/Python `greedy_best_first.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/greedy_best_first.py)
