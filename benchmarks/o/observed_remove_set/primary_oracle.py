"""Array-backed primary reference for a bounded observed-remove set."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 32
MAX_ELEMENTS = 16
MAX_TAGS = 2 * MAX_OPERATIONS
MAX_VALID_INPUT_LENGTH = 1 + 4 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, int, int, int], ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 4 * count:
        return None
    operations = []
    for i in range(count):
        opcode, replica, element, peer = values[1 + 4 * i:5 + 4 * i]
        if opcode in (0, 1, 2):
            if not 0 <= replica <= 1 or not 0 <= element < MAX_ELEMENTS or peer != 0:
                return None
        elif opcode in (3, 4):
            if not 0 <= replica <= 1 or element != 0 or not 0 <= peer <= 1:
                return None
        else:
            return None
        operations.append((opcode, replica, element, peer))
    return tuple(operations)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    operations = _parse(values, input_is_null, input_length)
    if operations is None:
        return INVALID_RESULT

    used = [False] * MAX_TAGS
    element_of = [0] * MAX_TAGS
    next_sequence = [0, 0]
    additions = [[False] * MAX_TAGS for _ in range(2)]
    removals = [[False] * MAX_TAGS for _ in range(2)]
    answer_bits = 0
    read_count = 0

    for opcode, replica, element, peer in operations:
        result = False
        if opcode == 0:
            tag = replica * MAX_OPERATIONS + next_sequence[replica]
            next_sequence[replica] += 1
            used[tag] = True
            element_of[tag] = element
            additions[replica][tag] = True
        elif opcode == 1:
            for tag in range(MAX_TAGS):
                if (additions[replica][tag] and not removals[replica][tag]
                        and used[tag] and element_of[tag] == element):
                    removals[replica][tag] = True
        elif opcode == 2:
            result = any(additions[replica][tag] and not removals[replica][tag]
                         and used[tag] and element_of[tag] == element
                         for tag in range(MAX_TAGS))
        elif opcode == 3:
            for tag in range(MAX_TAGS):
                additions[replica][tag] |= additions[peer][tag]
                removals[replica][tag] |= removals[peer][tag]
        else:
            result = all(not additions[replica][tag] or additions[peer][tag]
                         for tag in range(MAX_TAGS)) and all(
                             not removals[replica][tag] or removals[peer][tag]
                             for tag in range(MAX_TAGS))

        if opcode in (2, 4):
            if result:
                answer_bits |= 1 << read_count
            read_count += 1
    return answer_bits
