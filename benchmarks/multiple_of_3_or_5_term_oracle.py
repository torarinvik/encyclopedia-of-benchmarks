"""Oracle for the pinned MATLAB one-term Project Euler 1 helper."""

from __future__ import annotations

MAX_INPUT = 1_000_000_000
INVALID_RESULT = -1


def expected_result(value: int) -> int:
    """Return the value when it is a multiple of 3 or 5, otherwise zero."""
    if type(value) is not int or not 0 <= value <= MAX_INPUT:
        return INVALID_RESULT
    if value % 3 == 0 or value % 5 == 0:
        return value
    return 0
