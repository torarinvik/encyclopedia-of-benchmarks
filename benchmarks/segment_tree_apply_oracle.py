"""Oracle for the bounded range-multiply segment-tree workload."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 64
MAX_OPERATIONS = 20
MIN_INITIAL_VALUE = -1
MAX_INITIAL_VALUE = 1
MIN_MULTIPLIER = -2
MAX_MULTIPLIER = 2
MAX_ABS_ELEMENT = 1 << MAX_OPERATIONS
MAX_ABS_SUM = MAX_LENGTH * MAX_ABS_ELEMENT
CHECKSUM_OFFSET = MAX_ABS_SUM + 1
MAX_VALID_INPUT_VALUES = 146
MAX_PARSEABLE_INPUT_VALUES = 147
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the query checksum, or -1 for a malformed operation trace."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_VALUES
        or len(values) < 2
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT

    length = values[0]
    if not 1 <= length <= MAX_LENGTH or len(values) < length + 2:
        return INVALID_RESULT
    array = list(values[1 : length + 1])
    if any(not MIN_INITIAL_VALUE <= value <= MAX_INITIAL_VALUE for value in array):
        return INVALID_RESULT

    operation_count = values[length + 1]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    cursor = length + 2
    if cursor + 4 * operation_count > len(values):
        return INVALID_RESULT

    checksum = 0
    for operation_index in range(operation_count):
        opcode, left, right, argument = values[cursor : cursor + 4]
        cursor += 4
        if opcode == 0:
            if (
                not 0 <= left <= right < length
                or not MIN_MULTIPLIER <= argument <= MAX_MULTIPLIER
            ):
                return INVALID_RESULT
            for index in range(left, right + 1):
                array[index] *= argument
        elif opcode == 1:
            if not 0 <= left <= right < length or argument != 0:
                return INVALID_RESULT
            result = sum(array[left : right + 1])
            checksum += (operation_index + 1) * (result + CHECKSUM_OFFSET)
        else:
            return INVALID_RESULT

    if cursor != len(values):
        return INVALID_RESULT
    return checksum
