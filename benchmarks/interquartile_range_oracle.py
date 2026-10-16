"""Independent bounded oracle for the lower/upper-half interquartile range."""

from __future__ import annotations

INVALID_RESULT = -1.0e300
MIN_INPUT_LENGTH = 2
MAX_INPUT_LENGTH = 64
MAX_PARSEABLE_INPUT_LENGTH = 4096
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple))
            or not MIN_INPUT_LENGTH <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not MIN_VALUE <= value <= MAX_VALUE
                   for value in values)):
        return INVALID_RESULT

    ordered = sorted(values)
    half = len(ordered) // 2
    upper_start = half + len(ordered) % 2

    def median(part: list[int]) -> float:
        middle = len(part) // 2
        if len(part) % 2:
            return float(part[middle])
        return (part[middle - 1] + part[middle]) / 2.0

    return median(ordered[upper_start:]) - median(ordered[:half])
