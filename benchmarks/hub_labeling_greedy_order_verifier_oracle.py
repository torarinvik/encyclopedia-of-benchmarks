"""Independent exhaustive-path verifier for DOI 580's bounded greedy order."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_OUTPUT_BYTES = (1 + 2 * MAX_N + MAX_N * MAX_N) * 8


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges = []
    for i in range(m):
        u, v = values[2 + 2 * i:4 + 2 * i]
        if not 0 <= u < v < n or edges and edges[-1] >= (u, v):
            return None
        edges.append((u, v))
    return n, edges


def _enumerate_paths(n: int, edges: list[tuple[int, int]]):
    adj = [[] for _ in range(n)]
    for u, v in edges:
        adj[u].append(v); adj[v].append(u)
    paths: list[list[tuple[int, ...] | None]] = [[None] * n for _ in range(n)]
    for source in range(n):
        best = [n + 1] * n
        count = [0] * n
        chosen: list[tuple[int, ...] | None] = [None] * n
        path = [source]
        used = {source}
        def walk(current: int) -> None:
            distance = len(path) - 1
            if distance < best[current]:
                best[current] = distance; count[current] = 1; chosen[current] = tuple(path)
            elif distance == best[current]:
                count[current] = min(2, count[current] + 1)
            for nxt in adj[current]:
                if nxt not in used and len(path) < n:
                    used.add(nxt); path.append(nxt); walk(nxt); path.pop(); used.remove(nxt)
        walk(source)
        if any(c != 1 for c in count):
            return None
        paths[source] = chosen
    return paths


def _compute(n: int, edges: list[tuple[int, int]]) -> list[int] | None:
    paths = _enumerate_paths(n, edges)
    if paths is None:
        return None
    active = [[True] * n for _ in range(n)]
    order: list[int] = []
    for _ in range(n):
        coverage = [0] * n
        for source in range(n):
            for target in range(n):
                if active[source][target]:
                    for vertex in paths[source][target]:
                        coverage[vertex] += 1
        selected = min(range(n), key=lambda v: (-coverage[v], v))
        order.append(selected)
        for source in range(n):
            for target in range(n):
                if active[source][target] and selected in paths[source][target]:
                    active[source][target] = False
    rank = {v: i for i, v in enumerate(order)}
    labels: list[dict[int, int]] = [dict() for _ in range(n)]
    for u in range(n):
        for v in range(u, n):
            path = paths[u][v]
            hub = min(path, key=rank.__getitem__)
            labels[u][hub] = path.index(hub)
            labels[v][hub] = len(path) - 1 - path.index(hub)
    words = [n, *order]
    for vertex in range(n):
        hubs = sorted(labels[vertex])
        words.append(len(hubs))
        words.extend(hub | (labels[vertex][hub] << 8) for hub in hubs)
    return words


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    decoded = None if input_is_null else _decode(values)
    if decoded is None:
        return -1, b""
    words = _compute(*decoded)
    if words is None:
        return -1, b""
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
