"""Bond's composite-mask candidate scan for two array keys."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_VALID_INPUT_LENGTH = MAX_N + 3
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_VALUE = 255
MAX_WORKSPACE_BYTES = 0
ABSENT_CODE = 64
PACK_BASE = 65
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, key_a, key_b = values[:3]
    if (not 0 <= n <= MAX_N or len(values) != n + 3
            or not 0 <= key_a <= MAX_VALUE or not 0 <= key_b <= MAX_VALUE
            or key_a == key_b
            or any(not 0 <= value <= MAX_VALUE for value in values[3:])):
        return None
    return n, key_a, key_b, values[3:]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, key_a, key_b, items = parsed
    index_a = ABSENT_CODE
    index_b = ABSENT_CODE
    composite = key_a | key_b
    for index, value in enumerate(items):
        if index_a != ABSENT_CODE and index_b != ABSENT_CODE:
            break
        if value & composite != value:
            continue
        if index_a == ABSENT_CODE and value == key_a:
            index_a = index
        if index_b == ABSENT_CODE and value == key_b:
            index_b = index
    return index_a * PACK_BASE + index_b
