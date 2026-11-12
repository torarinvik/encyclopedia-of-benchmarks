"""Independent exhaustive rectangle verifier for a binary zero matrix."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ROWS = 16
MAX_COLUMNS = 16
MAX_VALID_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLUMNS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
           for value in values):
        return INVALID_RESULT
    rows, columns = values[0], values[1]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return INVALID_RESULT
    if input_length != 2 + rows * columns:
        return INVALID_RESULT
    cells = values[2:]
    if any(cell != 0 and cell != 1 for cell in cells):
        return INVALID_RESULT

    best = 0
    # Enumerate every rectangle and inspect its cells directly; no row heights
    # or monotone-stack boundaries are shared with the primary algorithm.
    for top in range(rows):
        for bottom in range(top, rows):
            for left in range(columns):
                for right in range(left, columns):
                    clear = True
                    for row in range(top, bottom + 1):
                        for column in range(right - left + 1):
                            if cells[row * columns + left + column] != 0:
                                clear = False
                                break
                        if not clear:
                            break
                    if clear:
                        best = max(best, (bottom - top + 1) * (right - left + 1))
    return best
