"""Reference Newton's second law over the package's bounded integer domain."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 2
MIN_INPUT_VALUE = -1_000
MAX_INPUT_VALUE = 1_000


def expected_result(values: list[int]) -> float:
    """Decode `[mass, acceleration]` and return the signed force."""
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    mass, acceleration = values
    if any(not MIN_INPUT_VALUE <= value <= MAX_INPUT_VALUE for value in values):
        return INVALID_RESULT
    return float(mass * acceleration)
