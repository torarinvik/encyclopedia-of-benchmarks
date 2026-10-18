"""Oracle for the pinned Lua uint53 predicate."""
from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 1
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
UINT53_LIMIT = 1 << 53


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return INVALID_RESULT
    if input_length != MAX_INPUT_LENGTH:
        return INVALID_RESULT
    return int(0 <= values[0] < UINT53_LIMIT)
