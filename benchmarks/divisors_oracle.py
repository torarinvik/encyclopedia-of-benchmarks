"""Independent oracle for the bounded divisor-set bit-mask benchmark."""

from __future__ import annotations

MAX_N = 62
MAX_INPUT_LENGTH = 2  # allow a one-extra-value malformed record
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    if len(values) != 1 or not 1 <= values[0] <= MAX_N:
        return INVALID_RESULT
    n = values[0]
    mask = 0
    divisor = 1
    while divisor * divisor <= n:
        if n % divisor == 0:
            mask |= 1 << divisor
            paired = n // divisor
            mask |= 1 << paired
        divisor += 1
    return mask
