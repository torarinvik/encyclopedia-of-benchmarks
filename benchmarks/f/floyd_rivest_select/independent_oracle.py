"""Independent full-sort reference for the bounded selection profile."""

from __future__ import annotations

from collections.abc import Sequence

MIN_ITEMS = 1
MAX_ITEMS = 64
MIN_VALUE = 0
MAX_VALUE = (1 << 31) - 1
MAX_INPUT_LENGTH = MAX_ITEMS + 3


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return -1
    count, rank = values[:2]
    if (not MIN_ITEMS <= count <= MAX_ITEMS or not 0 <= rank < count
            or len(values) != count + 2):
        return -1
    items = list(values[2:])
    if (any(not MIN_VALUE <= value <= MAX_VALUE for value in items)
            or len(set(items)) != count):
        return -1
    items.sort()
    return items[rank]
