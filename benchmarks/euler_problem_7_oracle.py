"""Independent trial-division oracle for Project Euler problem 7."""

from __future__ import annotations

from collections.abc import Sequence
from math import isqrt

MAX_ORDINAL = 10_001
MAX_PARSEABLE_INPUT_LENGTH = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the requested 1-based prime or -1 for malformed input."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1
    if len(values) != 1 or not 1 <= values[0] <= MAX_ORDINAL:
        return -1

    target = values[0]
    count = 0
    candidate = 1
    while count < target:
        candidate += 1
        if all(candidate % divisor for divisor in range(2, isqrt(candidate) + 1)):
            count += 1
    return candidate
