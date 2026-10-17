"""Independent oracle for the bounded Dart list-queue operation trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_OPERATION_COUNT = 64
MAX_QUEUE_SIZE = 10
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATION_COUNT
MAX_OUTPUT_BYTES = 520
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Encode query results followed by the queue's final active elements."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATION_COUNT:
        return INVALID_RESULT, b""

    operations: list[tuple[int, int | None]] = []
    cursor = 1
    for _ in range(operation_count):
        if cursor >= len(values):
            return INVALID_RESULT, b""
        opcode = values[cursor]
        cursor += 1
        if opcode == 0:
            if cursor >= len(values):
                return INVALID_RESULT, b""
            value = values[cursor]
            cursor += 1
            if not I32_MIN <= value <= I32_MAX:
                return INVALID_RESULT, b""
            operations.append((opcode, value))
        elif opcode in (1, 2):
            operations.append((opcode, None))
        else:
            return INVALID_RESULT, b""
    if cursor != len(values):
        return INVALID_RESULT, b""

    queue: list[int] = []
    queries: list[tuple[int, int]] = []
    for opcode, argument in operations:
        if opcode == 0:
            if len(queue) >= MAX_QUEUE_SIZE:
                return INVALID_RESULT, b""
            assert argument is not None
            queue.append(argument)
        elif opcode == 1:
            if queue:
                queries.append((1, queue.pop(0)))
            else:
                queries.append((3, 0))
        else:
            queries.append((2, len(queue)))

    output_words = [len(queries)]
    for kind, value in queries:
        output_words.extend((kind, value))
    output_words.append(len(queue))
    output_words.extend(queue)
    encoded = struct.pack("<" + "i" * len(output_words), *output_words)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
