"""Oracle for the bounded recursive integer-power benchmark."""
from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if values is None or not isinstance(values, (list, tuple)) or len(values) != 2:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != 2):
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    base, exponent = values
    if not -10 <= base <= 10 or not 0 <= exponent <= 15:
        return INVALID_RESULT
    result = 1
    for _ in range(exponent):
        result *= base
    if not I64_MIN <= result <= I64_MAX:
        return INVALID_RESULT
    return result
