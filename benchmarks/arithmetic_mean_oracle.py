"""Independent bounded oracle for the arithmetic mean array benchmark."""

from __future__ import annotations

MAX_INPUT_LENGTH = 64
MAX_ABS_VALUE = 1_000_000
INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return sum(values) / len(values) inside the benchmark's input domain."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -MAX_ABS_VALUE <= value <= MAX_ABS_VALUE
                   for value in values)):
        return INVALID_RESULT
    return sum(values) / len(values)
