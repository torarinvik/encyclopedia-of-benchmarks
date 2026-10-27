"""Independent Floyd–Warshall verifier for weighted greedy spanners."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = MAX_N * (MAX_N - 1) // 2
MAX_INPUT_LENGTH = 3 + 3 * MAX_M + 1
MAX_OUTPUT_BYTES = MAX_M


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m, k = values[:3]
    if not 2 <= n <= MAX_N or not 0 <= m <= MAX_M or not 1 <= k <= 3 or len(values) != 3 + 3 * m:
        return None
    edges = []
    seen = set()
    for i in range(m):
        u, v, weight = values[3 + 3 * i:6 + 3 * i]
        if not 0 <= u < v < n or not 1 <= weight <= 32 or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v, weight))
    return n, k, edges


def _floyd_distance(n: int, adjacency: list[list[int]], source: int, target: int) -> int:
    distance = [[10**18] * n for _ in range(n)]
    for i in range(n):
        distance[i][i] = 0
        for j in range(n):
            if adjacency[i][j] > 0:
                distance[i][j] = adjacency[i][j]
    for via in range(n):
        for left in range(n):
            for right in range(n):
                candidate = distance[left][via] + distance[via][right]
                if candidate < distance[left][right]:
                    distance[left][right] = candidate
    return distance[source][target]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or values is None:
        return invalid, b""
    decoded = _decode(values)
    if decoded is None:
        return invalid, b""
    n, k, edges = decoded
    adjacency = [[0] * n for _ in range(n)]
    chosen = [0] * len(edges)
    for index in sorted(range(len(edges)), key=lambda i: (edges[i][2], edges[i][0], edges[i][1])):
        u, v, weight = edges[index]
        if _floyd_distance(n, adjacency, u, v) > (2 * k - 1) * weight:
            chosen[index] = 1
            adjacency[u][v] = adjacency[v][u] = weight
    payload = bytes(chosen)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
