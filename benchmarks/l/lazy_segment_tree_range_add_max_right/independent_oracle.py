"""Direct-array update and prefix-scan oracle, independent of lazy propagation."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_LIMIT,
    MAX_N,
    MAX_OPERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_VALUE,
)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    n, operation_count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    if len(values) != 2 + n + 4 * operation_count or len(values) > MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT
    data = list(values[2:2 + n])
    if any(not 0 <= value <= MAX_VALUE for value in data):
        return INVALID_RESULT

    result = 0
    query_index = 0
    cursor = 2 + n
    for _ in range(operation_count):
        opcode, left, right, extra = values[cursor:cursor + 4]
        cursor += 4
        if opcode == 0:
            if not 0 <= left <= n or not left <= right <= n or not 0 <= extra <= MAX_VALUE:
                return INVALID_RESULT
            for index in range(left, right):
                data[index] += extra
        elif opcode == 1:
            if not 0 <= left <= n or not 0 <= right <= MAX_LIMIT or extra != 0:
                return INVALID_RESULT
            total = 0
            boundary = left
            while boundary < n and total + data[boundary] <= right:
                total += data[boundary]
                boundary += 1
            result |= boundary << (5 * query_index)
            query_index += 1
        else:
            return INVALID_RESULT
    return result
