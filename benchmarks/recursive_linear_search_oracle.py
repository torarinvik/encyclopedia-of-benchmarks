"""Oracle for the bounded distinct-value recursive linear search."""
from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_N = 64
MAX_COUNT = MAX_N
MAX_INPUT_LENGTH = MAX_N + 3
MAX_VALID_INPUT_LENGTH = MAX_N + 2
MIN_VALUE = I32_MIN
MAX_VALUE = I32_MAX


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if not 1 <= len(values) <= MAX_N + 2:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    n, target = values[:2]
    if not 2 <= n <= MAX_N or len(values) != n + 2:
        return INVALID_RESULT
    if not I32_MIN <= target <= I32_MAX:
        return INVALID_RESULT
    items = values[2:]
    if any(value < I32_MIN or value > I32_MAX for value in items):
        return INVALID_RESULT
    if len(set(items)) != n:
        return INVALID_RESULT
    try:
        return items.index(target)
    except ValueError:
        return -1


def expected_result(values: Sequence[int] | None) -> int:
    """Compatibility entry point used by the shared i64-array-scalar runner."""
    return expected_output(values)
