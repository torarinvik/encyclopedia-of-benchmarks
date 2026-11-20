"""Independent direct-scan oracle for bounded sorted-array search."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT, MAX_N, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALUE, MIN_VALUE,
)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    n, target = values[:2]
    if (not 0 <= n <= MAX_N or len(values) != n + 2
            or not MIN_VALUE <= target <= MAX_VALUE):
        return INVALID_RESULT
    items = values[2:]
    if (any(not MIN_VALUE <= item <= MAX_VALUE for item in items)
            or any(items[i - 1] >= items[i] for i in range(1, n))):
        return INVALID_RESULT
    for index, item in enumerate(items):
        if item == target:
            return index
        if item > target:
            return INVALID_RESULT
    return INVALID_RESULT
