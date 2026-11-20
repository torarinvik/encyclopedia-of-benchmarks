"""Sequential range scans for Mo-with-modifications fixtures."""

from __future__ import annotations

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_N,
    MAX_OPERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALUE,
)


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    n, operation_count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) < 2 + n:
        return None
    data = list(values[2:2 + n])
    if any(not 0 <= value <= MAX_VALUE for value in data):
        return None
    cursor = 2 + n
    operations = []
    for _ in range(operation_count):
        if cursor + 3 > len(values):
            return None
        kind, first, second = values[cursor:cursor + 3]
        cursor += 3
        if kind == 0:
            if not 0 <= first < n or not 0 <= second <= MAX_VALUE:
                return None
        elif kind == 1:
            if not 0 <= first <= second < n:
                return None
        else:
            return None
        operations.append((kind, first, second))
    if cursor != len(values):
        return None
    return data, operations


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    data, operations = decoded
    checksum = 0
    query_index = 0
    for kind, first, second in operations:
        if kind == 0:
            data[first] = second
        else:
            distinct_count = len(set(data[first:second + 1]))
            query_index += 1
            checksum += query_index * (distinct_count + 1)
    return checksum
