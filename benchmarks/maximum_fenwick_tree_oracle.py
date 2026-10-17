"""Oracle for the bounded pinned Python maximum Fenwick tree trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_SIZE = 64
MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 2 + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return query results as LE i64 words or the ABI error status."""
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
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    size, operation_count = values[:2]
    if not 1 <= size <= MAX_SIZE or not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""
    if len(values) != 2 + 3 * operation_count:
        return INVALID_RESULT, b""

    data = [0] * size
    results: list[int] = []
    position = 2
    for _ in range(operation_count):
        opcode, first, second = values[position : position + 3]
        position += 3
        if opcode == 0:
            if not 0 <= first < size or not 0 <= second <= I32_MAX:
                return INVALID_RESULT, b""
            data[first] = second
        elif opcode == 1:
            if not 0 <= first <= second <= size:
                return INVALID_RESULT, b""
            results.append(max(data[first:second], default=0))
        else:
            return INVALID_RESULT, b""

    output = b"".join(struct.pack("<q", result) for result in results)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
