"""Independent bounded oracle for the ordered harmonic-mean calculation."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 64
MAX_VALUE = 1_000


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return count divided by the source's ordered reciprocal sum."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not 1 <= value <= MAX_VALUE for value in values)):
        return INVALID_RESULT
    reciprocal_sum = 0.0
    for value in values:
        reciprocal_sum += 1.0 / value
    return len(values) / reciprocal_sum
