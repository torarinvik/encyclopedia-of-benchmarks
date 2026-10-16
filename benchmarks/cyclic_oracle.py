"""Reference behavior for the pinned Go circular doubly linked list."""

from __future__ import annotations

import struct

MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 40_000
MAX_STEP = 1_000_000
INT32_MIN = -(2**31)
INT32_MAX = 2**31 - 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not values or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != 1 + 2 * operation_count:
        return -1, b""

    # The logical order starts at Head; rotation changes that starting node.
    items: list[int] = []
    records: list[int] = []
    query_count = 0
    position = 1
    for operation_index in range(operation_count):
        operation, argument = values[position:position + 2]
        position += 2
        if operation not in range(6):
            return -1, b""
        if operation == 0:  # Add
            if not INT32_MIN <= argument <= INT32_MAX:
                return -1, b""
            items.append(argument)
        elif operation == 1:  # Rotate
            if not -MAX_STEP <= argument <= MAX_STEP:
                return -1, b""
            if items:
                offset = argument % len(items)
                if offset:
                    items = items[offset:] + items[:offset]
        elif operation == 2:  # Delete
            if argument != 0:
                return -1, b""
            deleted = int(bool(items))
            if items:
                del items[0]
            records.extend((operation_index, operation, 1, deleted))
            query_count += 1
        elif operation == 3:  # Walk: capture the order printed by Go's method
            if argument != 0:
                return -1, b""
            records.extend((operation_index, operation, len(items), *items))
            query_count += 1
        elif operation == 4:  # JosephusProblem; this source deletes after Rotate(k), then Rotate(-1)
            if not -MAX_STEP <= argument <= MAX_STEP or not items:
                return -1, b""
            while len(items) > 1:
                offset = argument % len(items)
                if offset:
                    items = items[offset:] + items[:offset]
                del items[0]
                if items:
                    items = items[-1:] + items[:-1]
            winner = items[0]
            items.clear()  # JosephusProblem calls Destroy before returning.
            records.extend((operation_index, operation, 1, winner))
            query_count += 1
        else:  # Destroy
            if argument != 0:
                return -1, b""
            items.clear()

    output_values = [query_count, *records, len(items), *items]
    output = struct.pack("<" + "q" * len(output_values), *output_values)
    return len(output), output
