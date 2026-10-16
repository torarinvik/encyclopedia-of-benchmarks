"""Oracle for the bounded Solidity uint16 exponentiation contract."""

from __future__ import annotations

MAX_BASE = 255
MAX_EXPONENT = 7
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    base, exponent = values
    if not 0 <= base <= MAX_BASE or not 0 <= exponent <= MAX_EXPONENT:
        return INVALID_RESULT
    return base**exponent
