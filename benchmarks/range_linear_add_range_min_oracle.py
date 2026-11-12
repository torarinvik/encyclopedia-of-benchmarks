"""Direct-array oracle for the bounded range-linear-add/range-min profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 64
MAX_OPERATIONS = 64
MAX_INITIAL_ABS = 1_000_000
MAX_SLOPE_ABS = 99
MAX_INTERCEPT_ABS = 100_000
CHECKSUM_OFFSET = 8_000_000
MAX_VALID_INPUT_VALUES = 386
MAX_PARSEABLE_INPUT_VALUES = 387
MAX_ABS_VALUE = MAX_INITIAL_ABS + MAX_OPERATIONS * (
    MAX_SLOPE_ABS * (MAX_LENGTH - 1) + MAX_INTERCEPT_ABS
)
MAX_CHECKSUM = MAX_OPERATIONS * (MAX_OPERATIONS + 1) // 2 * (
    MAX_ABS_VALUE + CHECKSUM_OFFSET
)
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Apply operations literally to a list and return their weighted min checksum."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 3
        or len(values) > MAX_PARSEABLE_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT

    n, q = values[0], values[1]
    if not 1 <= n <= MAX_LENGTH or not 1 <= q <= MAX_OPERATIONS or len(values) < n + 2:
        return INVALID_RESULT

    data = list(values[2 : 2 + n])
    if any(not -MAX_INITIAL_ABS <= value <= MAX_INITIAL_ABS for value in data):
        return INVALID_RESULT

    cursor = n + 2
    checksum = 0
    for operation_index in range(q):
        if cursor >= len(values):
            return INVALID_RESULT
        opcode = values[cursor]
        if opcode == 0:
            if cursor + 5 > len(values):
                return INVALID_RESULT
            left, right, slope, intercept = values[cursor + 1 : cursor + 5]
            cursor += 5
            if not 0 <= left < right <= n:
                return INVALID_RESULT
            if not -MAX_SLOPE_ABS <= slope <= MAX_SLOPE_ABS:
                return INVALID_RESULT
            if not -MAX_INTERCEPT_ABS <= intercept <= MAX_INTERCEPT_ABS:
                return INVALID_RESULT
            for index in range(left, right):
                data[index] += slope * index + intercept
        elif opcode == 1:
            if cursor + 3 > len(values):
                return INVALID_RESULT
            left, right = values[cursor + 1 : cursor + 3]
            cursor += 3
            if not 0 <= left < right <= n:
                return INVALID_RESULT
            checksum += (operation_index + 1) * (min(data[left:right]) + CHECKSUM_OFFSET)
        else:
            return INVALID_RESULT

    if cursor != len(values):
        return INVALID_RESULT
    return checksum
