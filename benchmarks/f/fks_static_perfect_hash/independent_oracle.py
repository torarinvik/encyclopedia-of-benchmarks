"""Independent direct-set oracle for the bounded membership-mask contract."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if (len(values) < 2 or len(values) > 19
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT
    stored_count, query_count = values[0], values[1]
    if not (0 <= stored_count <= 8 and 0 <= query_count <= 8):
        return INVALID_RESULT
    if len(values) != 2 + stored_count + query_count:
        return INVALID_RESULT
    stored = list(values[2:2 + stored_count])
    asked = list(values[2 + stored_count:])
    if any(value < 0 or value > 255 for value in stored + asked):
        return INVALID_RESULT
    if len(set(stored)) != stored_count:
        return INVALID_RESULT
    members = set(stored)
    mask = 0
    for bit, query in enumerate(asked):
        if query in members:
            mask |= 1 << bit
    return mask
