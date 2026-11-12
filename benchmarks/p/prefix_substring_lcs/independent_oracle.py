"""Independent prefix/substring LCS oracle using a fresh DP per query."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_STRING_LENGTH = 32
MAX_QUERIES = 64
MAX_INPUT_LENGTH = 3 + 2 * MAX_STRING_LENGTH + 3 * MAX_QUERIES
MAX_OUTPUT_BYTES = 8 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1


def _decode(values: Sequence[int] | None, input_length: int | None):
    if not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    m, n, q = values[0], values[1], values[2]
    if not 1 <= m <= MAX_STRING_LENGTH or not 1 <= n <= MAX_STRING_LENGTH or not 1 <= q <= MAX_QUERIES:
        return None
    if len(values) != 3 + m + n + 3 * q:
        return None
    at = 3
    s = values[at:at + m]
    at += m
    t = values[at:at + n]
    at += n
    if any(x < 97 or x > 122 for x in s) or any(x < 97 or x > 122 for x in t):
        return None
    requests = []
    while at < len(values):
        a, left, right = values[at], values[at + 1], values[at + 2]
        at += 3
        if a < 0 or a > m or left < 0 or left > right or right > n:
            return None
        requests.append((a, left, right))
    return s, t, requests


def _one_lcs(left: Sequence[int], right: Sequence[int]) -> int:
    previous = [0] * (len(right) + 1)
    for left_symbol in left:
        current = [0] * (len(right) + 1)
        for j, right_symbol in enumerate(right, start=1):
            if left_symbol == right_symbol:
                current[j] = previous[j - 1] + 1
            else:
                current[j] = max(previous[j], current[j - 1])
        previous = current
    return previous[-1]


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(input_is_null) is not bool or input_is_null:
        return -1, b""
    decoded = _decode(values, input_length)
    if decoded is None:
        return -1, b""
    if (type(output_is_null) is not bool
            or capacity is not None and
                (type(capacity) is not int or capacity < 0)):
        return -1, b""
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if output_is_null or actual_capacity < 8 * len(decoded[2]):
        return -2, b""
    s, t, requests = decoded
    answers = [_one_lcs(s[:a], t[b:c]) for a, b, c in requests]
    encoded = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(encoded), encoded
