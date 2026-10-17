"""Bounded reference oracle for the pinned Java single-stack MinStack."""

from __future__ import annotations

import struct

MAX_OPERATIONS = 256
MAX_INPUT_VALUES = 1 + 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = (1 + 3 * MAX_OPERATIONS) * 8
INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Execute a packed push/pop/top/getMin trace and encode its query records."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1, b""

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return -1, b""

    operations: list[tuple[int, int]] = []
    position = 1
    query_count = 0
    for _ in range(operation_count):
        if position >= len(values):
            return -1, b""
        opcode = values[position]
        position += 1
        operand = 0
        if opcode == 0:
            if position >= len(values):
                return -1, b""
            operand = values[position]
            position += 1
            if not INT32_MIN <= operand <= INT32_MAX:
                return -1, b""
        elif opcode in (2, 3):
            query_count += 1
        elif opcode != 1:
            return -1, b""
        operations.append((opcode, operand))
    if position != len(values):
        return -1, b""

    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    needed = (1 + 3 * query_count) * 8
    if output_is_null or output_capacity < needed:
        return -2, b""

    stack: list[tuple[int, int]] = []
    records: list[int] = [query_count]
    for opcode, operand in operations:
        if opcode == 0:
            minimum = operand if not stack else min(stack[-1][1], operand)
            stack.append((operand, minimum))
        elif opcode == 1:
            if stack:
                stack.pop()
        elif not stack:
            records.extend((opcode, 1, 0))
        elif opcode == 2:
            records.extend((opcode, 0, stack[-1][0]))
        else:
            records.extend((opcode, 0, stack[-1][1]))

    output = struct.pack("<" + "q" * len(records), *records)
    return len(output), output
