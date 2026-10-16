"""Bounded oracle for the Rust lazy segment tree's range-add/range-sum mode."""

from __future__ import annotations

MAX_ITEMS = 256
MAX_OPERATIONS = 512
MAX_INPUT_LENGTH = 2 + MAX_ITEMS + 4 * MAX_OPERATIONS
VALUE_LIMIT = 1_000_000
QUERY_OFFSET = 131_328_000_001
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT

    item_count = values[0]
    if not 1 <= item_count <= MAX_ITEMS:
        return INVALID_RESULT
    if len(values) < item_count + 2:
        return INVALID_RESULT

    items = list(values[1:item_count + 1])
    if any(not -VALUE_LIMIT <= value <= VALUE_LIMIT for value in items):
        return INVALID_RESULT

    operation_count = values[item_count + 1]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    if len(values) != item_count + 2 + 4 * operation_count:
        return INVALID_RESULT

    for operation in range(operation_count):
        position = item_count + 2 + 4 * operation
        opcode, left, right, delta = values[position:position + 4]
        if not 0 <= left < right <= item_count:
            return INVALID_RESULT
        if opcode == 0:
            if not -VALUE_LIMIT <= delta <= VALUE_LIMIT:
                return INVALID_RESULT
        elif opcode == 1:
            if delta != 0:
                return INVALID_RESULT
        else:
            return INVALID_RESULT

    checksum = 0
    for operation in range(operation_count):
        position = item_count + 2 + 4 * operation
        opcode, left, right, delta = values[position:position + 4]
        if opcode == 0:
            for index in range(left, right):
                items[index] += delta
        else:
            checksum += sum(items[left:right]) + QUERY_OFFSET
    return checksum
