"""Independent bounded oracle for the Euclidean distance array benchmark."""

from __future__ import annotations

import math

MAX_DIMENSION = 128
MAX_INPUT_LENGTH = 1 + 2 * MAX_DIMENSION
MAX_COORDINATE = 1_000_000
INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return sqrt of the sum of squared coordinate differences in the bounded domain."""
    if (not isinstance(values, (list, tuple)) or not values
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    dimension = values[0]
    if (not 0 <= dimension <= MAX_DIMENSION or len(values) != 1 + 2 * dimension
            or any(not -MAX_COORDINATE <= value <= MAX_COORDINATE for value in values[1:])):
        return INVALID_RESULT
    first = values[1:1 + dimension]
    second = values[1 + dimension:]
    squared_distance = sum((left - right) ** 2 for left, right in zip(first, second))
    return math.sqrt(float(squared_distance))
