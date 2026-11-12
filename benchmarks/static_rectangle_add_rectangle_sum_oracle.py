"""Geometric-overlap oracle for static rectangle-add/rectangle-sum calls."""

import struct
from typing import Sequence

MAX_N = 32
MAX_Q = 32
MAX_COORD = 1_000_000
MOD = 998_244_353
MAX_VALID_INPUT_LENGTH = 2 + 5 * MAX_N + 4 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_Q * 8
MAX_WORKSPACE_BYTES = 524_288


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return -1, b""
    if len(values) != 2 + 5 * n + 4 * q:
        return -1, b""

    updates = []
    offset = 2
    for _ in range(n):
        left, down, right, up, weight = values[offset:offset + 5]
        offset += 5
        if (not 0 <= left < right <= MAX_COORD
                or not 0 <= down < up <= MAX_COORD
                or not 0 <= weight < MOD):
            return -1, b""
        updates.append((left, down, right, up, weight))
    queries = []
    for _ in range(q):
        left, down, right, up = values[offset:offset + 4]
        offset += 4
        if not 0 <= left < right <= MAX_COORD or not 0 <= down < up <= MAX_COORD:
            return -1, b""
        queries.append((left, down, right, up))

    required = 8 * q
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""

    answers = []
    for left, down, right, up in queries:
        total = 0
        for add_left, add_down, add_right, add_up, weight in updates:
            overlap_x = max(0, min(right, add_right) - max(left, add_left))
            overlap_y = max(0, min(up, add_up) - max(down, add_down))
            term = (weight * (overlap_x % MOD) % MOD) * (overlap_y % MOD) % MOD
            total = (total + term) % MOD
        answers.append(total)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
