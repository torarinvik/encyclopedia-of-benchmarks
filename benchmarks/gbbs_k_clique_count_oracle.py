"""Bounded GBBS fixed-k clique counting oracle (the k=4 profile)."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 24
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return None
    neighbors = [set() for _ in range(n)]
    for pos in range(2, len(values), 2):
        u, v = values[pos:pos + 2]
        if not 0 <= u < v < n or v in neighbors[u]:
            return None
        neighbors[u].add(v)
        neighbors[v].add(u)
    return n, neighbors


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    n, neighbors = parsed

    # Match the source's supported ORIGINAL orientation by keeping only edges
    # from smaller IDs to larger IDs. The source filter also removes vertices
    # of degree below k-1; such vertices cannot participate in a 4-clique.
    outgoing = [set(v for v in row if v > u and len(row) >= 3)
                if len(row) >= 3 else set()
                for u, row in enumerate(neighbors)]
    total = 0
    for a in range(n):
        for b in outgoing[a]:
            common_ab = outgoing[a] & outgoing[b]
            for c in common_ab:
                total += sum(d in outgoing[c] for d in common_ab if d > c)
    encoded = struct.pack("<q", total)
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, encoded
