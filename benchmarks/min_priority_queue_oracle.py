"""Oracle for the bounded Java/JavaScript min-priority queue trace."""

from __future__ import annotations

from collections.abc import Sequence
import heapq
import struct

MAX_CAPACITY = 64
MAX_OPERATION_COUNT = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_OPERATION_COUNT
MAX_OUTPUT_BYTES = 4 * (1 + 2 * MAX_OPERATION_COUNT)
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
    """Return query results as ``[count, kind, value, ...]`` signed-i32 words."""
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

    capacity, operation_count = values[:2]
    if not 0 <= capacity <= MAX_CAPACITY:
        return INVALID_RESULT, b""
    if not 0 <= operation_count <= MAX_OPERATION_COUNT:
        return INVALID_RESULT, b""

    operations: list[tuple[int, int | None]] = []
    cursor = 2
    for _ in range(operation_count):
        if cursor >= len(values):
            return INVALID_RESULT, b""
        opcode = values[cursor]
        cursor += 1
        if opcode == 0:
            if cursor >= len(values):
                return INVALID_RESULT, b""
            key = values[cursor]
            cursor += 1
            if not I32_MIN <= key <= I32_MAX:
                return INVALID_RESULT, b""
            operations.append((opcode, key))
        elif opcode in (1, 2, 3, 4):
            operations.append((opcode, None))
        else:
            return INVALID_RESULT, b""
    if cursor != len(values):
        return INVALID_RESULT, b""

    heap: list[int] = []
    queries: list[tuple[int, int]] = []
    for opcode, key in operations:
        if opcode == 0:
            if len(heap) >= capacity:
                return INVALID_RESULT, b""
            assert key is not None
            heapq.heappush(heap, key)
        elif opcode == 1:
            if not heap:
                return INVALID_RESULT, b""
            queries.append((1, heap[0]))
        elif opcode == 2:
            if not heap:
                return INVALID_RESULT, b""
            queries.append((2, heapq.heappop(heap)))
        elif opcode == 3:
            queries.append((3, int(not heap)))
        else:
            queries.append((4, int(len(heap) == capacity)))

    encoded = bytearray(struct.pack("<i", len(queries)))
    for kind, value in queries:
        encoded.extend(struct.pack("<ii", kind, value))
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), bytes(encoded)
