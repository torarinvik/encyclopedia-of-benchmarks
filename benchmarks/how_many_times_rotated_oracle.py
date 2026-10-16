"""Independent reference for the Java rotated-array pivot search."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ARRAY_LENGTH = 256
MAX_INPUT_LENGTH = MAX_ARRAY_LENGTH
I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int]) -> int:
    """Return the minimum element's index for a valid distinct rotated array."""
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_INPUT_LENGTH + 1
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    if len(values) > MAX_ARRAY_LENGTH or any(value < I32_MIN or value > I32_MAX for value in values):
        return INVALID_RESULT
    if not values:
        return 0

    # The pinned method uses binary search. Scanning for the minimum keeps this
    # oracle independent while matching it on the source's valid input domain.
    minimum = min(range(len(values)), key=values.__getitem__)
    return minimum
