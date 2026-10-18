"""Oracle for the common min-priority-queue subset of two pinned APIs."""

from __future__ import annotations

from collections.abc import Sequence
import heapq
import struct

MAX_OPERATIONS = 64
MAX_PRIORITY = (1 << 31) - 1
MIN_PRIORITY = -(1 << 31)
MAX_INPUT_VALUES = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_VALUES + 1
MAX_OUTPUT_BYTES = 4 * MAX_OPERATIONS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_result(values: Sequence[int] | None) -> bytes | None:
    """Return chronological peek/dequeue results as signed i32 little-endian bytes."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return None
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None

    heap: list[int] = []
    seen: set[int] = set()
    results: list[int] = []
    offset = 1
    for _ in range(operation_count):
        if offset >= len(values):
            return None
        operation = values[offset]
        offset += 1
        if operation == 0:
            if offset >= len(values):
                return None
            priority = values[offset]
            offset += 1
            if not MIN_PRIORITY <= priority <= MAX_PRIORITY or priority in seen:
                return None
            seen.add(priority)
            heapq.heappush(heap, priority)
        elif operation == 1:
            if not heap:
                return None
            results.append(heap[0])
        elif operation == 2:
            if not heap:
                return None
            results.append(heapq.heappop(heap))
        else:
            return None
    if offset != len(values):
        return None
    if len(results) > MAX_OPERATIONS:
        return None
    return b"".join(struct.pack("<i", value) for value in results)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return result byte count and encoded retrieval outputs, or ABI errors."""
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
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""

    output = expected_result(values)
    if output is None:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
