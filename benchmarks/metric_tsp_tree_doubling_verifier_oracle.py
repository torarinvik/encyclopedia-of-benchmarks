"""Independent Prim-based verifier for metric TSP tree doubling."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT = 65


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
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 2 or len(values) > MAX_INPUT or any(
            type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + n * n:
        return -1, b""
    d = [values[1 + i * n:1 + (i + 1) * n] for i in range(n)]
    if (any(not 0 <= d[i][j] <= 10000 for i in range(n) for j in range(n))
            or any(d[i][i] != 0 for i in range(n))
            or any(d[i][j] != d[j][i] for i in range(n) for j in range(n))
            or any(d[i][j] > d[i][k] + d[k][j]
                   for i in range(n) for j in range(n) for k in range(n))):
        return -1, b""

    in_tree = [False] * n
    in_tree[0] = True
    adjacency = [[False] * n for _ in range(n)]
    for _ in range(n - 1):
        best: tuple[int, int, int] | None = None
        for u in range(n):
            if not in_tree[u]:
                continue
            for v in range(n):
                if in_tree[v] or u == v:
                    continue
                edge = (d[u][v], min(u, v), max(u, v))
                if best is None or edge < best:
                    best = edge
        assert best is not None
        _, u, v = best
        adjacency[u][v] = adjacency[v][u] = True
        in_tree[u if not in_tree[u] else v] = True

    order: list[int] = []
    pending = [0]
    visited = [False] * n
    while pending:
        v = pending.pop()
        if visited[v]:
            continue
        visited[v] = True
        order.append(v)
        for w in range(n - 1, -1, -1):
            if adjacency[v][w] and not visited[w]:
                pending.append(w)
    cycle = [*order, 0]
    length_value = sum(d[cycle[i]][cycle[i + 1]] for i in range(n))
    output = b"".join(struct.pack("<q", x) for x in (length_value, *cycle))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
