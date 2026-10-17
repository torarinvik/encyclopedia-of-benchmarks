"""Oracle for the bounded C# list-based stack operation trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_INITIAL_ITEMS = 32
MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 2 + MAX_INITIAL_ITEMS + 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 16 * MAX_OPERATIONS
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and one [opcode,result] record for each operation."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""

    initial_count = values[0]
    if not 0 <= initial_count <= MAX_INITIAL_ITEMS:
        return INVALID_RESULT, b""
    operation_count_index = 1 + initial_count
    if operation_count_index >= len(values):
        return INVALID_RESULT, b""
    initial_items = values[1:operation_count_index]
    if any(not I32_MIN <= value <= I32_MAX for value in initial_items):
        return INVALID_RESULT, b""
    operation_count = values[operation_count_index]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""

    stack = list(reversed(initial_items))
    position = operation_count_index + 1
    records: list[tuple[int, int]] = []
    for _ in range(operation_count):
        if position >= len(values):
            return INVALID_RESULT, b""
        opcode = values[position]
        position += 1
        if opcode in (1, 5):
            if position >= len(values):
                return INVALID_RESULT, b""
            argument = values[position]
            position += 1
            if not I32_MIN <= argument <= I32_MAX:
                return INVALID_RESULT, b""
            if opcode == 1:
                stack.insert(0, argument)
                records.append((opcode, 0))
            else:
                records.append((opcode, int(argument in stack)))
        elif opcode == 2:
            if not stack:
                return INVALID_RESULT, b""
            records.append((opcode, stack.pop(0)))
        elif opcode == 3:
            if not stack:
                return INVALID_RESULT, b""
            records.append((opcode, stack[0]))
        elif opcode == 4:
            records.append((opcode, len(stack)))
        elif opcode == 6:
            stack.clear()
            records.append((opcode, 0))
        else:
            return INVALID_RESULT, b""
    if position != len(values):
        return INVALID_RESULT, b""

    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<qq", opcode, value) for opcode, value in records)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
