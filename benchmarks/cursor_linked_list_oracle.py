"""Reference behavior for the pinned Java array-backed cursor linked list."""

from __future__ import annotations

import struct

CURSOR_SPACE_SIZE = 100
MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = (1 + 2 * MAX_OPERATIONS + 2 + 3 * CURSOR_SPACE_SIZE) * 8
INT32_MIN = -(2**31)
INT32_MAX = 2**31 - 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not values or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""
    operation_count = values[0]
    if (not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 1 + 2 * operation_count):
        return -1, b""

    elements: list[int | None] = [None] * CURSOR_SPACE_SIZE
    links = list(range(1, CURSOR_SPACE_SIZE + 1))
    links[-1] = 0
    head = -1
    count = 0
    query_results: list[tuple[int, int]] = []

    def find_first(value: int) -> tuple[int, int]:
        previous = -1
        current = head
        logical_index = 0
        while current != -1:
            if elements[current] == value:
                return previous, current
            previous, current = current, links[current]
            logical_index += 1
        return -1, -1

    def free(index: int) -> None:
        nonlocal links
        old_free_head = links[0]
        links[0] = index
        elements[index] = None
        links[index] = old_free_head

    def remove_value(value: int) -> bool:
        nonlocal head, count
        if head == -1:
            return False
        previous, current = find_first(value)
        if current == -1:
            return False
        next_index = links[current]
        if previous == -1:
            free(current)
            head = next_index
        else:
            links[previous] = next_index
            free(current)
        count -= 1
        return True

    position = 1
    for _ in range(operation_count):
        operation, argument = values[position:position + 2]
        position += 2
        if operation not in range(5) or not INT32_MIN <= argument <= INT32_MAX:
            return -1, b""
        if operation == 0:  # append
            available = links[0]
            if available == 0:
                return -1, b""
            links[0] = links[available]
            links[available] = -1
            elements[available] = argument
            if head == -1:
                head = available
            else:
                cursor = head
                while links[cursor] != -1:
                    cursor = links[cursor]
                links[cursor] = available
            links[available] = -1
            count += 1
        elif operation == 1:  # remove first matching element
            if not remove_value(argument):
                return -1, b""
        elif operation == 2:  # removeByIndex calls get(index), then remove(value)
            if not 0 <= argument < count:
                return -1, b""
            cursor = head
            for _ in range(argument):
                cursor = links[cursor]
            value = elements[cursor]
            if value is None or not remove_value(value):
                return -1, b""
        elif operation == 3:  # get
            if 0 <= argument < count:
                cursor = head
                for _ in range(argument):
                    cursor = links[cursor]
                value = elements[cursor]
                if value is None:
                    return -1, b""
                query_results.append((1, value))
            else:
                query_results.append((0, 0))
        else:  # indexOf
            _, found = find_first(argument)
            if found == -1:
                query_results.append((0, 0))
            else:
                cursor = head
                logical_index = 0
                while cursor != found:
                    cursor = links[cursor]
                    logical_index += 1
                query_results.append((1, logical_index))

    output_values = [len(query_results)]
    for found, result in query_results:
        output_values.extend((found, result))
    output_values.extend((head, count))
    for index in range(CURSOR_SPACE_SIZE):
        value = elements[index]
        output_values.extend((int(value is not None), 0 if value is None else value, links[index]))
    output = struct.pack("<" + "q" * len(output_values), *output_values)
    return len(output), output
