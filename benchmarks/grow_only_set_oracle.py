"""Oracle for the pinned Java grow-only-set CRDT trace."""

from __future__ import annotations

MAX_OPERATIONS = 12
MAX_ELEMENT = 15
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
LEFT_SHIFT = 12
RIGHT_SHIFT = 28
QUERY_COUNT_SHIFT = 44


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != 1 + 2 * operation_count:
        return -1

    left: set[int] = set()
    right: set[int] = set()
    answers = 0
    query_count = 0
    for offset in range(operation_count):
        opcode, argument = values[1 + 2 * offset:3 + 2 * offset]
        if opcode in (0, 1, 2, 3):
            if not 0 <= argument <= MAX_ELEMENT:
                return -1
        elif opcode in (4, 5, 6, 7):
            if argument != 0:
                return -1
        else:
            return -1

        if opcode == 0:
            left.add(argument)
        elif opcode == 1:
            right.add(argument)
        elif opcode == 2:
            answers |= int(argument in left) << query_count
            query_count += 1
        elif opcode == 3:
            answers |= int(argument in right) << query_count
            query_count += 1
        elif opcode == 4:
            answers |= int(left <= right) << query_count
            query_count += 1
        elif opcode == 5:
            answers |= int(right <= left) << query_count
            query_count += 1
        elif opcode == 6:
            left.update(right)
        else:
            right.update(left)

    left_mask = sum(1 << value for value in left)
    right_mask = sum(1 << value for value in right)
    return (answers | (left_mask << LEFT_SHIFT) | (right_mask << RIGHT_SHIFT)
            | (query_count << QUERY_COUNT_SHIFT))
