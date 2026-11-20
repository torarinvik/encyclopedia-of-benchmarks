"""Direct row-mask oracle, independent of k²-tree navigation."""

from __future__ import annotations

import struct
from collections.abc import Sequence

BAD = -1
NO_OUTPUT = -2
MAX_N = 32
MAX_Q = 128
MAX_VALID_INPUT_LENGTH = 418
MAX_PARSEABLE_INPUT_LENGTH = 419
MAX_OUTPUT_BYTES = 1032


def _parse(values, input_length, input_is_null):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= 1 << 63
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or len(values) < n + 2:
        return None
    limit = (1 << n) - 1
    rows = tuple(values[1:1 + n])
    if any(type(mask) is not int or not 0 <= mask <= limit for mask in rows):
        return None
    q = values[n + 1]
    if type(q) is not int or not 0 <= q <= MAX_Q or len(values) != n + 2 + 3 * q:
        return None
    queries = []
    for at in range(n + 2, len(values), 3):
        op, u, v = values[at:at + 3]
        if not 0 <= u < n:
            return None
        if op == 0:
            if not 0 <= v < n:
                return None
        elif op == 1:
            if v != 0:
                return None
        else:
            return None
        queries.append((op, u, v))
    return n, rows, queries


def _run(values, input_length=None, input_is_null=False):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return None
    n, rows, queries = parsed
    output = [len(queries)]
    for op, u, v in queries:
        if op == 0:
            output.append((rows[u] >> v) & 1)
        else:
            output.append(rows[u])
    return output


def expected_output(values: Sequence[int] | None, output_capacity=None,
                    output_is_null=False, input_is_null=False,
                    input_length=None):
    words = _run(values, input_length, input_is_null)
    if words is None:
        return BAD, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return NO_OUTPUT, b""
    return len(payload), payload
