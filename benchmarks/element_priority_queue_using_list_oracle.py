"""Oracle for the bounded ElementPriorityQueue trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_OPERATIONS = 256
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 1024
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return dequeued minimum values as little-endian i64 words, or an ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0 or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if not values or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""

    operation_count = values[0]
    if (not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) > MAX_VALID_INPUT_LENGTH):
        return INVALID_RESULT, b""

    queue: list[int] = []
    answers: list[int] = []
    position = 1

    for _ in range(operation_count):
        if position + 1 >= len(values):
            return INVALID_RESULT, b""
        opcode, argument = values[position : position + 2]
        position += 2

        if opcode == 0:
            if not I32_MIN <= argument <= I32_MAX or len(queue) == 100:
                return INVALID_RESULT, b""
            queue.append(argument)
        elif opcode == 1:
            if argument != 0 or not queue:
                return INVALID_RESULT, b""
            minimum = min(queue)
            # list.remove removes the first equal value, preserving the source's
            # FIFO behavior among equal minima (although their values coincide).
            queue.remove(minimum)
            answers.append(minimum)
        else:
            return INVALID_RESULT, b""

    if position != len(values):
        return INVALID_RESULT, b""

    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<q", value) for value in answers)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
