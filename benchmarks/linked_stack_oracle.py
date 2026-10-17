"""Oracle for the bounded Lua linked-stack operation trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 24 * MAX_OPERATIONS
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _record(opcode: int, result_tag: int, value: int) -> bytes:
    return struct.pack("<qqq", opcode, result_tag, value)


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and per-operation result records."""
    if input_length is None:
        declared_length = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared_length = input_length
    else:
        return INVALID_RESULT, b""

    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or type(input_is_null) is not bool
        or (input_is_null and len(values) != 0)
        or (not input_is_null and declared_length != len(values))
        or declared_length > MAX_INPUT_LENGTH
    ):
        return INVALID_RESULT, b""
    if input_is_null or declared_length < 1:
        return INVALID_RESULT, b""

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""

    operations: list[tuple[int, int]] = []
    cursor = 1
    for _ in range(operation_count):
        if cursor >= len(values):
            return INVALID_RESULT, b""
        opcode = values[cursor]
        cursor += 1
        if opcode == 1:
            if cursor >= len(values):
                return INVALID_RESULT, b""
            value = values[cursor]
            cursor += 1
            if not I32_MIN <= value <= I32_MAX:
                return INVALID_RESULT, b""
            operations.append((opcode, value))
        elif opcode in (2, 3, 4):
            operations.append((opcode, 0))
        else:
            return INVALID_RESULT, b""
    if cursor != len(values):
        return INVALID_RESULT, b""

    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if output_is_null:
        return OUTPUT_ERROR, b""

    stack: list[int] = []
    records: list[bytes] = []
    for opcode, argument in operations:
        if opcode == 1:
            stack.append(argument)
            records.append(_record(opcode, 2, 0))
        elif opcode == 2:
            if stack:
                records.append(_record(opcode, 0, stack[-1]))
            else:
                records.append(_record(opcode, 2, 0))
        elif opcode == 3:
            if stack:
                records.append(_record(opcode, 0, stack.pop()))
            else:
                records.append(_record(opcode, 2, 0))
        else:
            records.append(_record(opcode, 1, int(not stack)))

    output = b"".join(records)
    if output_capacity is not None and output_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
