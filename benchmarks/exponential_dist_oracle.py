"""Oracle for the bounded selector adapter to C++ exponential_dist."""

from __future__ import annotations

MAX_INPUT_LENGTH = 3
SCALE = 1_000_000
MAX_RATE_MICRO = 1_000_000_000
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    if len(values) != 2:
        return INVALID_RESULT
    operation, rate_micro = values
    if operation not in (0, 1, 2) or not 1 <= rate_micro <= MAX_RATE_MICRO:
        return INVALID_RESULT

    rate = rate_micro / SCALE
    if operation == 1:
        return 1.0 / (rate * rate)
    return 1.0 / rate
