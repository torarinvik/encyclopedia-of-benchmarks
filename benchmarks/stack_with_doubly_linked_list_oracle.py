"""Oracle for the bounded doubly linked stack operation trace."""

from collections.abc import Sequence
import struct

MAX_OPERATION_COUNT = 64
MAX_INPUT_LENGTH = 129
MAX_OUTPUT_BYTES = 1536
INVALID_RESULT = -1
CAPACITY_ERROR = -2
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def _record(opcode: int, tag: int, value: int) -> bytes:
    return struct.pack("<qqq", opcode, tag, value)


def expected_output(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return INVALID_RESULT, b""

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATION_COUNT:
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
            item = values[cursor]
            cursor += 1
            if not I32_MIN <= item <= I32_MAX:
                return INVALID_RESULT, b""
            operations.append((opcode, item))
        elif opcode in (2, 3, 4):
            operations.append((opcode, 0))
        else:
            return INVALID_RESULT, b""
    if cursor != len(values):
        return INVALID_RESULT, b""

    stack: list[int] = []
    output = bytearray()
    for opcode, argument in operations:
        if opcode == 1:
            stack.append(argument)
            output.extend(_record(opcode, 2, 0))
        elif opcode == 2:
            output.extend(_record(opcode, 0, stack.pop()) if stack else _record(opcode, 2, 0))
        elif opcode == 3:
            output.extend(_record(opcode, 0, stack[-1]) if stack else _record(opcode, 2, 0))
        else:
            output.extend(_record(opcode, 0, len(stack)))

    if capacity is not None and (type(capacity) is not int or capacity < len(output)):
        return CAPACITY_ERROR, b""
    return len(output), bytes(output)
