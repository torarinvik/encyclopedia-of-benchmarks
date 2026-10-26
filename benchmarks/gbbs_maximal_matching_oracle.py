"""Bounded deterministic edge-priority profile of GBBS maximal matching."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_EDGES
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
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 3 * m:
        return None
    ranks = values[2:2 + m]
    if sorted(ranks) != list(range(m)):
        return None
    endpoints = values[2 + m:]
    adjacency = [[False] * n for _ in range(n)]
    edges = []
    for pos in range(0, len(endpoints), 2):
        u, v = endpoints[pos:pos + 2]
        if not 0 <= u < v < n or adjacency[u][v]:
            return None
        adjacency[u][v] = adjacency[v][u] = True
        edges.append((u, v))
    return n, m, ranks, edges


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
    n, m, ranks, edges = parsed
    output_bytes = 8 * m
    if output_is_null or capacity is not None and capacity < output_bytes:
        return OUTPUT_ERROR, b""

    # With a total edge order, repeated commits of live local minima equal an
    # ascending-priority greedy scan; rank zero is the highest priority.
    order = [0] * m
    for edge, rank in enumerate(ranks):
        order[rank] = edge
    matched = [False] * n
    chosen = [0] * m
    for edge in order:
        u, v = edges[edge]
        if not matched[u] and not matched[v]:
            chosen[edge] = 1
            matched[u] = matched[v] = True
    encoded = b"".join(struct.pack("<q", value) for value in chosen)
    return output_bytes, encoded
