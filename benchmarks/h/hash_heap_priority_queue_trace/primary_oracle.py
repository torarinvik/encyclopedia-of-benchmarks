"""Bounded order-preserving hash-heap priority-queue trace."""
from __future__ import annotations

import heapq

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
SIZE_MAX = (1 << 64) - 1
MIN_UNIVERSE = 1
MAX_UNIVERSE = 128
MAX_BUCKETS = 8
MAX_OPERATIONS = 64
MAX_VALID_INPUT_LENGTH = 3 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_OPERATIONS + 1)
WORKSPACE_BYTES = 4096


def _encode(words: list[int]) -> bytes:
    return b"".join(value.to_bytes(8, "little", signed=True) for value in words)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and
            (type(capacity) is not int or not 0 <= capacity <= SIZE_MAX)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= SIZE_MAX)):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    universe, bucket_count, operation_count = values[:3]
    if (not MIN_UNIVERSE <= universe <= MAX_UNIVERSE
            or not 1 <= bucket_count <= min(MAX_BUCKETS, universe)
            or not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 3 + 2 * operation_count):
        return -1, b""

    operations: list[tuple[int, int]] = []
    for offset in range(3, len(values), 2):
        opcode, operand = values[offset], values[offset + 1]
        if opcode == 0:
            if not 0 <= operand < universe:
                return -1, b""
        elif opcode in (1, 2):
            if operand != 0:
                return -1, b""
        else:
            return -1, b""
        operations.append((opcode, operand))

    # Each ordered bucket is a min-heap of (key, insertion-operation-index).
    # The monotone bucket map makes the first nonempty bucket globally minimal.
    buckets: list[list[tuple[int, int]]] = [[] for _ in range(bucket_count)]
    words = [operation_count]
    for operation_index, (opcode, operand) in enumerate(operations):
        if opcode == 0:
            bucket = (operand * bucket_count) // universe
            heapq.heappush(buckets[bucket], (operand, operation_index))
            words.append(-2)
            continue
        first = next((index for index, heap in enumerate(buckets) if heap), -1)
        if first < 0:
            words.append(-1)
            continue
        key, insertion_index = buckets[first][0]
        words.append((insertion_index << 8) | key)
        if opcode == 2:
            heapq.heappop(buckets[first])

    output = _encode(words)
    required = len(output)
    if output_is_null or capacity is not None and capacity < required:
        return -2, b""
    return required, output
