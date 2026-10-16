"""Oracle for the Haskell empty-allowed maximum-subarray variant."""

from __future__ import annotations

MAX_LENGTH = 1024
MAX_INPUT_LENGTH = MAX_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    if any(value < -(2**31) or value > 2**31 - 1 for value in values):
        return INVALID_RESULT

    best = current = 0
    for value in values:
        current = max(0, current + value)
        best = max(best, current)
    return best
