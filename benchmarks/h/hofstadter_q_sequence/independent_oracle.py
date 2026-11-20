"""Memoized recursive reference for Hofstadter's Q recurrence."""
from __future__ import annotations

from functools import lru_cache

MAX_INDEX = 128


def sequence_term(index: int) -> int | None:
    if type(index) is not int or not 1 <= index <= MAX_INDEX:
        return None

    @lru_cache(maxsize=None)
    def q(position: int) -> int | None:
        if position in (1, 2):
            return 1
        if position < 1 or position > index:
            return None
        older = q(position - 2)
        newer = q(position - 1)
        if older is None or newer is None:
            return None
        left = position - newer
        right = position - older
        if not (1 <= left < position and 1 <= right < position):
            return None
        left_value = q(left)
        right_value = q(right)
        if left_value is None or right_value is None:
            return None
        return left_value + right_value

    return q(index)


def expected_result(values, *, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if (values is None or input_is_null or not isinstance(values, (list, tuple))
            or len(values) != 1):
        return -1
    if (type(values[0]) is not int or not -(1 << 63) <= values[0] < (1 << 63)
            or (input_length is not None and input_length != 1)):
        return -1
    result = sequence_term(values[0])
    return -1 if result is None else result
