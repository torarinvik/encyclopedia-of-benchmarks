"""Direct array scan for max_right, independent of the segment-tree oracle."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
MAX_N = 16
MAX_OPERATIONS = 12
MAX_LIMIT = 16_000


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if (len(values) < 2 or len(values) > 55
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT
    n, operation_count = values[:2]
    if not 0 <= n <= MAX_N or not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    if len(values) != 2 + n + 3 * operation_count:
        return INVALID_RESULT
    data = list(values[2:2 + n])
    if any(not 0 <= value <= 1000 for value in data):
        return INVALID_RESULT

    answer_count = 0
    result = 0
    cursor = 2 + n
    for _ in range(operation_count):
        opcode, first, second = values[cursor:cursor + 3]
        cursor += 3
        if opcode == 0:
            if not 0 <= first < n or not 0 <= second <= 1000:
                return INVALID_RESULT
            data[first] = second
        elif opcode == 1:
            if not 0 <= first <= n or not 0 <= second <= MAX_LIMIT:
                return INVALID_RESULT
            running = 0
            boundary = first
            while boundary < n and running + data[boundary] <= second:
                running += data[boundary]
                boundary += 1
            result |= boundary << (5 * answer_count)
            answer_count += 1
        else:
            return INVALID_RESULT
    return result
