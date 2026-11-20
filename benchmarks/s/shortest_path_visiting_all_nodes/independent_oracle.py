"""Independent all-pairs-distance plus subset-DP reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 10
MAX_M = 45
MAX_VALID_INPUT_LENGTH = 92
MAX_PARSEABLE_INPUT_LENGTH = 93
INVALID_RESULT = -1
_INF = 1 << 30


def _matrix(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> list[list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return None
    if m > n * (n - 1) // 2 or len(values) != 2 + 2 * m:
        return None
    distance = [[_INF] * n for _ in range(n)]
    for vertex in range(n):
        distance[vertex][vertex] = 0
    edges: set[tuple[int, int]] = set()
    offset = 2
    for _ in range(m):
        u, v = values[offset], values[offset + 1]
        offset += 2
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        edge = (min(u, v), max(u, v))
        if edge in edges:
            return None
        edges.add(edge)
        distance[u][v] = 1
        distance[v][u] = 1
    for middle in range(n):
        for source in range(n):
            if distance[source][middle] == _INF:
                continue
            for target in range(n):
                candidate = distance[source][middle] + distance[middle][target]
                if candidate < distance[source][target]:
                    distance[source][target] = candidate
    if any(distance[0][vertex] == _INF for vertex in range(n)):
        return None
    return distance


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    distance = _matrix(values, input_is_null, input_length)
    if distance is None:
        return INVALID_RESULT
    n = len(distance)
    state_count = 1 << n
    dp = [[_INF] * n for _ in range(state_count)]
    for start in range(n):
        dp[1 << start][start] = 0
    for mask in range(1, state_count):
        for last in range(n):
            current = dp[mask][last]
            if current == _INF:
                continue
            for next_vertex in range(n):
                bit = 1 << next_vertex
                if mask & bit:
                    continue
                candidate = current + distance[last][next_vertex]
                next_mask = mask | bit
                if candidate < dp[next_mask][next_vertex]:
                    dp[next_mask][next_vertex] = candidate
    return min(dp[-1])
