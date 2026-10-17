"""Oracle for the bounded C++ sparse-matrix classification benchmark."""
from __future__ import annotations

from collections.abc import Sequence

MIN_DIMENSION = 1
MAX_DIMENSION = 64
MIN_CELL = -(1 << 31)
MAX_CELL = (1 << 31) - 1
MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION
MAX_VALID_INPUT_LENGTH = 2 + MAX_CELLS
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1  # valid maximum plus one extra value
INVALID_RESULT = -1


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return 1 for a strict zero majority, 0 otherwise, or -1 if malformed."""
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if (not isinstance(values, (list, tuple))
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    rows, columns = values[0], values[1]
    if not MIN_DIMENSION <= rows <= MAX_DIMENSION:
        return INVALID_RESULT
    if not MIN_DIMENSION <= columns <= MAX_DIMENSION:
        return INVALID_RESULT
    cells = rows * columns
    if len(values) != 2 + cells:
        return INVALID_RESULT
    matrix_values = values[2:]
    if any(not MIN_CELL <= value <= MAX_CELL for value in matrix_values):
        return INVALID_RESULT
    zero_count = sum(value == 0 for value in matrix_values)
    return int(zero_count > cells // 2)
