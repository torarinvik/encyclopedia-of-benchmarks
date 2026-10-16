"""Independent oracle for the bounded multiply_digit contract."""

from __future__ import annotations

MIN_OPERAND = -1_000_000_000
MAX_OPERAND = 1_000_000_000
MAX_INPUT_LENGTH = 3  # includes one overlong input for the ABI boundary
INVALID_RESULT = -(1 << 63)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    first, second = values
    if not MIN_OPERAND <= first <= MAX_OPERAND or not MIN_OPERAND <= second <= MAX_OPERAND:
        return INVALID_RESULT
    return first * second
