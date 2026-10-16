"""Oracle for bounded one-based grid coordinates from a linear index."""

from __future__ import annotations

MAX_COLUMNS = 1_000
MAX_INDEX = 10_000
MAX_INPUT_LENGTH = 4  # permit a complete one-extra-value malformed record
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    if len(values) != 3:
        return INVALID_RESULT
    operation, columns, index = values
    if operation not in (0, 1) or not 1 <= columns <= MAX_COLUMNS or not 0 <= index <= MAX_INDEX:
        return INVALID_RESULT
    if operation == 0:
        remaining = index
        while remaining + 1 > columns:
            remaining -= columns
        return remaining + 1
    return index // columns + 1
