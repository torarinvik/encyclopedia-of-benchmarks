"""Independent logical FIFO oracle for the pinned Clojure persistent-list queue."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_OPERATIONS = 256
MAX_QUEUE_LENGTH = 64
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211
MASK63 = (1 << 63) - 1


def _trace_hash(operation_count: int, observations: list[tuple[int, int]], queue: list[int]) -> int:
    payload = bytearray(struct.pack("<H", operation_count))
    for opcode, result in observations:
        payload.extend(struct.pack("<Bq", opcode, result))
    payload.extend(struct.pack("<H", len(queue)))
    for value in queue:
        payload.extend(struct.pack("<i", value))
    digest = FNV_OFFSET_BASIS
    for byte in payload:
        digest = ((digest ^ byte) * FNV_PRIME) & ((1 << 64) - 1)
    return digest & MASK63


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    """Return the low-63 FNV trace digest, or -1 for malformed input.

    The oracle models a logical oldest-to-newest Python list; the pinned source
    stores the same queue in reverse order using Clojure list `conj`/`drop-last`.
    """
    if type(input_is_null) is not bool:
        return -1
    if input_is_null:
        return -1
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) > MAX_VALID_INPUT_LENGTH:
        return -1
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != 1 + 2 * operation_count:
        return -1

    queue: list[int] = []
    observations: list[tuple[int, int]] = []
    for operation in range(operation_count):
        offset = 1 + 2 * operation
        opcode, argument = values[offset : offset + 2]
        if opcode == 0:
            if not I32_MIN <= argument <= I32_MAX or len(queue) >= MAX_QUEUE_LENGTH:
                return -1
            queue.append(argument)
            result = len(queue)
        elif opcode == 1:
            if argument != 0:
                return -1
            if queue:
                queue.pop(0)
            result = len(queue)
        elif opcode == 2:
            if argument != 0:
                return -1
            result = queue[0] if queue else I64_MIN
        elif opcode == 3:
            if argument != 0:
                return -1
            result = 1 if not queue else 0
        else:
            return -1
        observations.append((opcode, result))
    return _trace_hash(operation_count, observations, queue)
