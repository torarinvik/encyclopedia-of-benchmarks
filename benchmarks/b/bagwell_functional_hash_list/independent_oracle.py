"""Flat newest-first association scan, independent of block hash tables."""

from __future__ import annotations

import struct

BAD = -1
NO_OUTPUT = -2
ABSENT = -(1 << 63)
N_LIMIT = 32
Q_LIMIT = 32
INPUT_LIMIT = 131
OUTPUT_LIMIT = 256


def _simulate(data, input_length, input_null):
    if (type(input_null) is not bool or input_null
            or not isinstance(data, (list, tuple))
            or not 2 <= len(data) <= INPUT_LIMIT
            or any(type(item) is not int or item < -(1 << 63) or item >= 1 << 63
                   for item in data)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(data))):
        return None
    n = data[0]
    if not 0 <= n <= N_LIMIT:
        return None
    q_at = 1 + 2 * n
    if q_at >= len(data):
        return None
    q = data[q_at]
    if not 1 <= q <= Q_LIMIT or len(data) != 2 + 2 * n + 2 * q:
        return None
    entries = []
    for index in range(n):
        key = data[1 + 2 * index]
        value = data[2 + 2 * index]
        if not -(1 << 31) <= key < (1 << 31) or not -(1 << 31) <= value < (1 << 31):
            return None
        entries.append((key, value))
    results = []
    query_at = q_at + 1
    for index in range(q):
        root = data[query_at + 2 * index]
        key = data[query_at + 2 * index + 1]
        if not 0 <= root <= n or not -(1 << 31) <= key < (1 << 31):
            return None
        answer = ABSENT
        # Each front-cons prepends one entry, so the newest visible item is the
        # final pair in the first `root` pairs of the input.
        for old_key, old_value in reversed(entries[:root]):
            if old_key == key:
                answer = old_value
                break
        results.append(answer)
    return results


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    words = _simulate(values, input_length, input_is_null)
    if words is None:
        return BAD, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return NO_OUTPUT, b""
    return len(payload), payload
