"""Independent top-down oracle for the bounded Rodinia Pathfinder grid kernel."""

from functools import lru_cache

MAX_ROWS = 32
MAX_COLS = 32


def rodinia_pathfinder(values):
    if not isinstance(values, (list, tuple)) or len(values) < 4:
        return -1
    cols, rows, pyramid_height = values[:3]
    if (not isinstance(cols, int) or isinstance(cols, bool) or not 1 <= cols <= MAX_COLS
            or not isinstance(rows, int) or isinstance(rows, bool) or not 1 <= rows <= MAX_ROWS
            or not isinstance(pyramid_height, int) or isinstance(pyramid_height, bool)
            or not 1 <= pyramid_height <= 4):
        return -1
    if len(values) != 3 + cols * rows:
        return -1
    costs = values[3:]
    if any(not isinstance(cost, int) or isinstance(cost, bool) or not 0 <= cost <= 9 for cost in costs):
        return -1

    @lru_cache(maxsize=None)
    def path_cost(row, col):
        cost = costs[row * cols + col]
        if row == 0:
            return cost
        first = max(0, col - 1)
        last = min(cols - 1, col + 1)
        return cost + min(path_cost(row - 1, previous_col)
                          for previous_col in range(first, last + 1))

    return min(path_cost(rows - 1, col) for col in range(cols))
