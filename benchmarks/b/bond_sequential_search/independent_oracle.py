"""Independent two-pass linear-search oracle for Bond search results."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 4
MAX_VALUE = 255
ABSENT_CODE = 64
PACK_BASE = 65
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    n, key_a, key_b = values[:3]
    items = values[3:]
    if (not 0 <= n <= MAX_N or len(items) != n
            or not 0 <= key_a <= MAX_VALUE or not 0 <= key_b <= MAX_VALUE
            or key_a == key_b
            or any(not 0 <= value <= MAX_VALUE for value in items)):
        return INVALID_RESULT
    try:
        index_a = items.index(key_a)
    except ValueError:
        index_a = ABSENT_CODE
    try:
        index_b = items.index(key_b)
    except ValueError:
        index_b = ABSENT_CODE
    return index_a * PACK_BASE + index_b
