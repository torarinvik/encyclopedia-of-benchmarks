"""Oracle for the bounded list-based FIFO queue trace."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_OPERATIONS = 32
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16 * MAX_OPERATIONS
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""
    if not values or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) > MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT, b""

    head = -1
    tail = -1
    size = 0
    allocated = 0
    node_values = [0] * MAX_OPERATIONS
    next_node = [-1] * MAX_OPERATIONS
    records: list[tuple[int, int]] = []
    pos = 1

    for _ in range(operation_count):
        if pos >= len(values):
            return INVALID_RESULT, b""
        opcode = values[pos]
        pos += 1
        if opcode == 0:
            if pos >= len(values):
                return INVALID_RESULT, b""
            value = values[pos]
            pos += 1
            if not I32_MIN <= value <= I32_MAX or allocated >= MAX_OPERATIONS:
                return INVALID_RESULT, b""
            node_values[allocated] = value
            next_node[allocated] = -1
            if tail < 0:
                head = allocated
            else:
                next_node[tail] = allocated
            tail = allocated
            allocated += 1
            size += 1
            records.append((0, 1))
        elif opcode == 1:
            if head < 0:
                return INVALID_RESULT, b""
            value = node_values[head]
            head = next_node[head]
            size -= 1
            if head < 0:
                tail = -1
            records.append((1, value))
        elif opcode == 2:
            if head < 0:
                return INVALID_RESULT, b""
            records.append((2, node_values[head]))
        elif opcode == 3:
            head = tail = -1
            size = 0
            records.append((3, 1))
        elif opcode == 4:
            records.append((4, int(size == 0)))
        elif opcode == 5:
            records.append((5, 0))
        else:
            return INVALID_RESULT, b""

    if pos != len(values):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""

    output = b"".join(struct.pack("<qq", tag, value) for tag, value in records)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
