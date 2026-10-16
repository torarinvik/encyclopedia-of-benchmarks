"""Bounded independent oracle for the pinned tableau simplex source."""

from collections.abc import Sequence
import math

SCALE = 1_000_000
MAX_VARIABLES = 4
MAX_ARTIFICIAL = 2
MAX_ROWS = 8
MAX_COLUMNS = 16
MAX_INPUT_LENGTH = 132
MAX_ITERATIONS = 100
INVALID_RESULT = -1.0e300


def _finite_tableau(tableau: list[list[float]]) -> bool:
    return all(math.isfinite(value) for row in tableau for value in row)


def expected_result(values: Sequence[int]) -> float:
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return INVALID_RESULT

    n_vars, n_artificial, n_rows, n_cols = values[:4]
    if (not 2 <= n_vars <= MAX_VARIABLES or not 0 <= n_artificial <= MAX_ARTIFICIAL
            or not 3 <= n_rows <= MAX_ROWS or not n_vars + n_artificial + 1 <= n_cols <= MAX_COLUMNS
            or n_rows < (2 if n_artificial else 1) + 1
            or len(values) != 4 + n_rows * n_cols):
        return INVALID_RESULT

    tableau = [
        [values[4 + row * n_cols + col] / SCALE for col in range(n_cols)]
        for row in range(n_rows)
    ]
    if any(row[-1] < 0.0 for row in tableau) or not _finite_tableau(tableau):
        return INVALID_RESULT

    rows = n_rows
    cols = n_cols
    phase = 1 if n_artificial else 2
    finished = False
    for _ in range(MAX_ITERATIONS):
        if finished:
            result = abs(tableau[0][cols - 1])
            return result if math.isfinite(result) else INVALID_RESULT

        stages = 2 if phase == 1 else 1
        sign = 1.0 if phase == 1 else -1.0
        pivot_col = max(range(cols - 1), key=lambda col: sign * tableau[0][col])
        if sign * tableau[0][pivot_col] <= 0.0:
            if phase == 1:
                first_artificial_col = cols - n_artificial - 1
                compacted: list[list[float]] = []
                for row in tableau[1:]:
                    compacted.append([
                        value for col, value in enumerate(row)
                        if not first_artificial_col <= col < cols - 1
                    ])
                tableau = compacted
                rows -= 1
                cols -= n_artificial
                n_artificial = 0
                phase = 2
            else:
                finished = True
            continue

        candidates: list[tuple[float, int]] = []
        for row in range(stages, rows):
            divisor = tableau[row][pivot_col]
            if divisor > 0.0:
                ratio = tableau[row][cols - 1] / divisor
                if not math.isfinite(ratio):
                    return INVALID_RESULT
                candidates.append((ratio, row))
        if not candidates:
            return INVALID_RESULT
        _, pivot_row_index = min(candidates, key=lambda candidate: candidate[0])
        pivot_row = [value / tableau[pivot_row_index][pivot_col]
                     for value in tableau[pivot_row_index]]
        column_values = [tableau[row][pivot_col] for row in range(rows)]
        for row in range(rows):
            coefficient = column_values[row]
            for col in range(cols):
                tableau[row][col] += -coefficient * pivot_row[col]
        tableau[pivot_row_index] = pivot_row
        if not _finite_tableau(tableau):
            return INVALID_RESULT

    return INVALID_RESULT
