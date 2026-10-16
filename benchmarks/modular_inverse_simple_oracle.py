"""Independent oracle for the bounded iterative modular inverse."""

from __future__ import annotations

import math

MAX_X = 999
MAX_Y = 1_000
MAX_INPUT_LENGTH = 2
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT

    x, y = values
    if not 1 <= x <= MAX_X or not 2 <= y <= MAX_Y or math.gcd(x, y) != 1:
        return INVALID_RESULT
    return pow(x, -1, y)
