"""Kruskal tree-doubling oracle for bounded metric TSP."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT = 65
MAX_OUTPUT_BYTES = 80


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + n * n:
        return None
    dist = [values[1 + i * n:1 + (i + 1) * n] for i in range(n)]
    if any(not 0 <= dist[i][j] <= 10000 for i in range(n) for j in range(n)):
        return None
    if any(dist[i][i] != 0 for i in range(n)):
        return None
    if any(dist[i][j] != dist[j][i] for i in range(n) for j in range(n)):
        return None
    if any(dist[i][j] > dist[i][k] + dist[k][j]
           for i in range(n) for j in range(n) for k in range(n)):
        return None
    return n, dist


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, dist = parsed
    parent = list(range(n))

    def root(x: int) -> int:
        while parent[x] != x:
            x = parent[x]
        return x

    tree = [[] for _ in range(n)]
    edges = sorted((dist[u][v], u, v) for u in range(n) for v in range(u + 1, n))
    chosen = 0
    for _, u, v in edges:
        ru, rv = root(u), root(v)
        if ru != rv:
            parent[rv] = ru
            tree[u].append(v)
            tree[v].append(u)
            chosen += 1
            if chosen == n - 1:
                break
    order: list[int] = []
    stack = [0]
    visited = [False] * n
    while stack:
        vertex = stack.pop()
        if visited[vertex]:
            continue
        visited[vertex] = True
        order.append(vertex)
        stack.extend(sorted((v for v in tree[vertex] if not visited[v]), reverse=True))
    tour = [*order, 0]
    cost = sum(dist[tour[i]][tour[i + 1]] for i in range(n))
    output = b"".join(struct.pack("<q", x) for x in (cost, *tour))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
