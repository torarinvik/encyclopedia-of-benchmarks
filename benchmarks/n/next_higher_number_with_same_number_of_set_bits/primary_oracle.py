"""Formula-based reference for the bounded next fixed-popcount value."""

from __future__ import annotations

MIN_INPUT = 1
MAX_INPUT = (1 << 30) - 1
MAX_RESULT = 1_610_612_735
INVALID_RESULT = -1


def expected_result(value: int) -> int:
    if type(value) is not int or not MIN_INPUT <= value <= MAX_INPUT:
        return INVALID_RESULT
    lowest_one = value & -value
    raised = value + lowest_one
    result = raised | (((value ^ raised) // lowest_one) >> 2)
    return result if result <= MAX_RESULT else INVALID_RESULT
