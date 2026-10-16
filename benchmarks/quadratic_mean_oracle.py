"""Independent bounded oracle for the root-mean-square calculation."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 64
MAX_ABSOLUTE_VALUE = 1_000


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return sqrt of the source's ordered squared-value mean."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -MAX_ABSOLUTE_VALUE <= value <= MAX_ABSOLUTE_VALUE
                   for value in values)):
        return INVALID_RESULT
    squared_sum = 0.0
    for value in values:
        squared_value = float(value) * float(value)
        squared_sum += squared_value
    return math.sqrt(squared_sum / len(values))
