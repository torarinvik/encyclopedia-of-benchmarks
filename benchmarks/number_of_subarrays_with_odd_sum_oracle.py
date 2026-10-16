"""Independent prefix-parity oracle for odd-sum subarray counts."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 100_000
MIN_VALUE = -(1 << 31)
MAX_VALUE = (1 << 31) - 1
MODULUS = 1_000_000_007
INVALID_RESULT = -1


def expected_result(values: Sequence[int]) -> int:
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not MIN_VALUE <= value <= MAX_VALUE for value in values)
    ):
        return INVALID_RESULT

    even_prefixes = 1
    odd_prefixes = 0
    parity = 0
    result = 0
    for value in values:
        parity ^= value & 1
        if parity:
            result += even_prefixes
            odd_prefixes += 1
        else:
            result += odd_prefixes
            even_prefixes += 1
    return result % MODULUS
