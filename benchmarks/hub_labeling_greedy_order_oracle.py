"""Primary bounded implementation of DOI 580's greedy HHL ordering."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_OUTPUT_VALUES = 1 + 2 * MAX_N + MAX_N * MAX_N
MAX_OUTPUT_BYTES = MAX_OUTPUT_VALUES * 8


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    for i in range(m):
        u, v = values[2 + 2 * i:4 + 2 * i]
        if not 0 <= u < v < n:
            return None
        edge = (u, v)
        if edges and edges[-1] >= edge:
            return None
        edges.append(edge)
    return n, edges


def _trees(n: int, edges: list[tuple[int, int]]):
    adj = [[] for _ in range(n)]
    for u, v in edges:
        adj[u].append(v)
        adj[v].append(u)
    for row in adj:
        row.sort()
    parent = [[-1] * n for _ in range(n)]
    depth = [[-1] * n for _ in range(n)]
    for source in range(n):
        depth[source][source] = 0
        ways = [0] * n
        ways[source] = 1
        queue = [source]
        for u in queue:
            for v in adj[u]:
                if depth[source][v] < 0:
                    depth[source][v] = depth[source][u] + 1
                    parent[source][v] = u
                    ways[v] = ways[u]
                    queue.append(v)
                elif depth[source][v] == depth[source][u] + 1:
                    ways[v] = min(2, ways[v] + ways[u])
        if any(depth[source][v] < 0 or ways[v] != 1 for v in range(n)):
            return None
    return adj, parent, depth


def _ancestor(parent: list[list[int]], source: int, ancestor: int, target: int) -> bool:
    current = target
    while current >= 0:
        if current == ancestor:
            return True
        if current == source:
            break
        current = parent[source][current]
    return False


def _compute(n: int, edges: list[tuple[int, int]]) -> list[int] | None:
    built = _trees(n, edges)
    if built is None:
        return None
    _, parent, depth = built
    active = [[True] * n for _ in range(n)]
    order: list[int] = []
    for _ in range(n):
        counts = [0] * n
        for source in range(n):
            for target in range(n):
                if active[source][target]:
                    current = target
                    while current >= 0:
                        counts[current] += 1
                        if current == source:
                            break
                        current = parent[source][current]
        hub = max(range(n), key=lambda vertex: (counts[vertex], -vertex))
        order.append(hub)
        for source in range(n):
            for target in range(n):
                if active[source][target] and _ancestor(parent, source, hub, target):
                    active[source][target] = False

    rank = {vertex: position for position, vertex in enumerate(order)}
    labels: list[dict[int, int]] = [dict() for _ in range(n)]
    for u in range(n):
        for v in range(u, n):
            path = [v]
            current = v
            while current != u:
                current = parent[u][current]
                path.append(current)
            hub = min(path, key=rank.__getitem__)
            labels[u][hub] = depth[u][hub]
            labels[v][hub] = depth[v][hub]

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
    n, edges = decoded
    words = _compute(n, edges)
    if words is None:
        return -1, b""
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
