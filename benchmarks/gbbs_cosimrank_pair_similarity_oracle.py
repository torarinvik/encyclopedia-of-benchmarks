"""Bounded binary64 oracle for one exact CoSimRank source pair."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 8
MAX_EDGES = 24
MAX_ITERATIONS = 4
MAX_INPUT_LENGTH = 5 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or len(values) < 5
            or len(values) > MAX_INPUT_LENGTH
            or any(type(item) is not int or not I64_MIN <= item <= I64_MAX
                   for item in values)):
        return None
    n, m, source_u, source_v, iterations = values[:5]
    if (not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES
            or not 0 <= source_u < n or not 0 <= source_v < n
            or not 1 <= iterations <= MAX_ITERATIONS
            or len(values) != 5 + 2 * m):
        return None
    edges = []
    seen = set()
    degree = [0] * n
    for position in range(5, len(values), 2):
        u, v = values[position:position + 2]
        if not 0 <= u < n or not 0 <= v < n or u == v or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
        degree[u] += 1
    if any(value not in (0, 1, 2, 4) for value in degree):
        return None
    return n, source_u, source_v, iterations, edges, degree


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
    n, source_u, source_v, iterations, edges, degree = parsed
    current_u = [0.0] * n
    current_v = [0.0] * n
    current_u[source_u] = 1.0
    current_v[source_v] = 1.0
    similarity = 1.0 if source_u == source_v else 0.0
    discount = 0.5
    for _step in range(iterations):
        next_u = [0.0] * n
        next_v = [0.0] * n
        for u, v in edges:
            next_u[v] += current_u[u] / degree[u]
            next_v[v] += current_v[u] / degree[u]
        dot = 0.0
        for vertex in range(n):
            dot += next_u[vertex] * next_v[vertex]
        similarity += discount * dot
        current_u, current_v = next_u, next_v
        discount *= 0.5
    encoded = struct.pack("<d", similarity)
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, encoded
