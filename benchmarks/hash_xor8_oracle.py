"""Independent oracle for the bounded C-string XOR8 checksum."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 100_001
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_result(values: Sequence[int]) -> int:
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT
    total = 0
    for value in values:
        if value == 0:
            break
        if not 0 <= value <= 127:
            return INVALID_RESULT
        total = (total + value) & 0xFF
    return (-total) & 0xFF
