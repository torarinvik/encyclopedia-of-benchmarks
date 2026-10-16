"""Oracle for bounded int32-output Kadane variants."""

from __future__ import annotations

MAX_LENGTH = 1024
MAX_ABS_VALUE = 1_000_000
MAX_INPUT_LENGTH = MAX_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    if any(value < -MAX_ABS_VALUE or value > MAX_ABS_VALUE for value in values):
        return INVALID_RESULT

    current = best = values[0]
    for value in values[1:]:
        current = max(value, current + value)
        best = max(best, current)
    return best
