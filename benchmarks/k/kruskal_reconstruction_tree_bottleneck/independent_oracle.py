"""Minimax Floyd-Warshall reference for the Kruskal-tree contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_M = 16
MAX_Q = 8
MAX_WEIGHT = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = 3 + 3 * MAX_M + 2 * MAX_Q + 1
INFINITY = MAX_WEIGHT + 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, edge_count, query_count = values[:3]
    if (not 1 <= n <= MAX_N or not 0 <= edge_count <= MAX_M
            or not 1 <= query_count <= MAX_Q
            or len(values) != 3 + 3 * edge_count + 2 * query_count):
        return None
    cursor = 3
    edges: list[tuple[int, int, int]] = []
    for _ in range(edge_count):
        left, right, weight = values[cursor:cursor + 3]
        cursor += 3
        if not 0 <= left < n or not 0 <= right < n or not 0 <= weight <= MAX_WEIGHT:
            return None
        edges.append((left, right, weight))
    queries: list[tuple[int, int]] = []
    for _ in range(query_count):
        left, right = values[cursor:cursor + 2]
        cursor += 2
        if not 0 <= left < n or not 0 <= right < n:
            return None
        queries.append((left, right))
    return n, edges, queries


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, edges, queries = parsed
    bottleneck = [[INFINITY] * n for _ in range(n)]
    for vertex in range(n):
        bottleneck[vertex][vertex] = 0
    for left, right, weight in edges:
        bottleneck[left][right] = min(bottleneck[left][right], weight)
        bottleneck[right][left] = min(bottleneck[right][left], weight)
    for middle in range(n):
        for left in range(n):
            for right in range(n):
                through = max(bottleneck[left][middle], bottleneck[middle][right])
                if through < bottleneck[left][right]:
                    bottleneck[left][right] = through
    checksum = 0
    for index, (left, right) in enumerate(queries):
        answer = -1 if bottleneck[left][right] == INFINITY else bottleneck[left][right]
        checksum += (index + 1) * (answer + 2)
    return checksum
