"""Independent immutable-slice checker for the range-reversal workload."""

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


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_INPUT_LENGTH))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return -1, b""
    n, q = values[:2]
    if not 0 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) < n + 2:
        return -1, b""
    state = tuple(values[2:2 + n])
    if any(x < 0 or x > MAX_VALUE for x in state):
        return -1, b""
    cursor = 2 + n
    operations = []
    query_total = 0
    for _ in range(q):
        if cursor + 3 > len(values):
            return -1, b""
        kind, left, right = values[cursor:cursor + 3]
        cursor += 3
        if kind not in (0, 1) or not 0 <= left <= right <= n:
            return -1, b""
        operations.append((kind, left, right))
        query_total += kind
    if cursor != len(values):
        return -1, b""
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(actual_capacity) is not int
            or actual_capacity < 0 or output_is_null
            or actual_capacity < 8 * query_total):
        return -2, b""
    answers = []
    for kind, left, right in operations:
        if kind == 0:
            state = state[:left] + tuple(reversed(state[left:right])) + state[right:]
        else:
            answers.append(sum(state[left:right]))
    payload = b"".join(struct.pack("<q", value) for value in answers)
    return len(payload), payload
