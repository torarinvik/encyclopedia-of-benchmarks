"""Source-ordered bounded oracle for population standard deviation."""

from __future__ import annotations

import math

MAX_INPUT_LENGTH = 64
MAX_ABS_VALUE = 1_000_000
INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Mirror Java's two ordered passes and population denominator."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -MAX_ABS_VALUE <= value <= MAX_ABS_VALUE
                   for value in values)):
        return INVALID_RESULT

    average = 0.0
    for value in values:
        average += float(value)
    average /= len(values)

    variance = 0.0
    for value in values:
        variance += math.pow(float(value) - average, 2.0)
    variance /= len(values)
    return math.sqrt(variance)
