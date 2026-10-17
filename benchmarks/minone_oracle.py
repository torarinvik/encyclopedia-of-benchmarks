"""Oracle for the bounded integer adapter of MATLAB minone(x)."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_LENGTH = 64
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the exact sum of squares, or -1 for invalid input."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or any(value < MIN_VALUE or value > MAX_VALUE for value in values)
    ):
        return INVALID_RESULT
    return sum(value * value for value in values)
