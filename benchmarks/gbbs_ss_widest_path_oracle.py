"""Independent max-min closure oracle for the bounded GBBS widest-path profile."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_EDGE_CAPACITY = 32
SOURCE_INFINITY = 2_147_483_647
MAX_INPUT_LENGTH = 3 + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return (status, bytes), using Floyd-Warshall max-min closure."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return (-1, b"") if input_length in (None, 0) else (-1, b"")
    if (not isinstance(values, (tuple, list)) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if len(values) < 3:
        return -1, b""
    n, m, source = values[:3]
    if (not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES
            or not 0 <= source < n or len(values) != 3 + 3 * m):
        return -1, b""

    best = [[0] * n for _ in range(n)]
    best[source][source] = SOURCE_INFINITY
    for offset in range(3, len(values), 3):
        u, v, edge_capacity = values[offset:offset + 3]
        if (not 0 <= u < n or not 0 <= v < n
                or not 1 <= edge_capacity <= MAX_EDGE_CAPACITY):
            return -1, b""
        if edge_capacity > best[u][v]:
            best[u][v] = edge_capacity

    # This all-pairs closure is independent of the ports' selected-vertex
    # widest-path traversal and of the source's ring-bucket scheduler.
    for middle in range(n):
        for start in range(n):
            for end in range(n):
                candidate = min(best[start][middle], best[middle][end])
                if candidate > best[start][end]:
                    best[start][end] = candidate

    output = b"".join(struct.pack("<q", best[source][vertex]) for vertex in range(n))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
