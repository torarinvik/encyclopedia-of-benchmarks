"""Direct sequence oracle for bounded range reversal and range-sum operations."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_N = 64
MAX_Q = 32
MAX_VALUE = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, q = values[:2]
    if not 0 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    if len(values) < 2 + n:
        return None
    sequence = list(values[2:2 + n])
    if any(not 0 <= value <= MAX_VALUE for value in sequence):
        return None
    offset = 2 + n
    operations = []
    query_count = 0
    for _ in range(q):
        if offset + 3 > len(values):
            return None
        kind, left, right = values[offset:offset + 3]
        offset += 3
        if (kind not in (0, 1) or not 0 <= left <= right <= n):
            return None
        operations.append((kind, left, right))
        if kind == 1:
            query_count += 1
    if offset != len(values):
        return None
    return sequence, operations, query_count


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    sequence, operations, query_count = parsed
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return OUTPUT_ERROR, b""
    if output_is_null or effective_capacity < 8 * query_count:
        return OUTPUT_ERROR, b""
    answers = []
    for kind, left, right in operations:
        if kind == 0:
            start = left
            end = right - 1
            while start < end:
                sequence[start], sequence[end] = sequence[end], sequence[start]
                start += 1
                end -= 1
        else:
            answers.append(sum(sequence[left:right]))
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
