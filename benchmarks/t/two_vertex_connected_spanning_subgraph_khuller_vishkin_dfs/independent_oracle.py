"""Explicit-event-stack reference with direct vertex-deletion validation."""
from __future__ import annotations

import struct
from collections.abc import Sequence

from .primary_oracle import MAX_M, MAX_N, MAX_PARSEABLE_INPUT_LENGTH


def _deletion_connected(n: int, edges: list[tuple[int, int]], removed: int) -> bool:
    first = next(vertex for vertex in range(n) if vertex != removed)
    marked = {first}
    queue = [first]
    cursor = 0
    while cursor < len(queue):
        current = queue[cursor]
        cursor += 1
        for u, v in edges:
            if u == removed or v == removed:
                continue
            other = v if u == current else u if v == current else -1
            if other >= 0 and other not in marked:
                marked.add(other)
                queue.append(other)
    return len(marked) == n - 1


def _iterative_build(n: int, edges: list[tuple[int, int]]) -> list[tuple[int, int]]:
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    edge_index = {edge: eid for eid, edge in enumerate(edges)}
    for eid, (u, v) in enumerate(edges):
        adjacency[u].append((v, eid))
        adjacency[v].append((u, eid))

    state = [0] * n
    discovery = [-1] * n
    low = list(range(n))
    low_h = list(range(n))
    savior = list(range(n))
    selected = [False] * len(edges)
    parent_edge = [-1] * n
    tick = 0
    state[0] = 1
    discovery[0] = tick
    tick += 1
    frames: list[list[int]] = [[0, -1, 0]]  # vertex, parent, next adjacency index

    def earlier(a: int, b: int) -> bool:
        return discovery[a] < discovery[b]

    def add_back_edge(v: int) -> None:
        u, w = savior[v], low[v]
        pair = (u, w) if u < w else (w, u)
        selected[edge_index[pair]] = True

    while frames:
        v, parent, cursor = frames[-1]
        if cursor < len(adjacency[v]):
            frames[-1][2] += 1
            w, eid = adjacency[v][cursor]
            if state[w] == 0:
                selected[eid] = True
                parent_edge[w] = eid
                state[w] = 1
                discovery[w] = tick
                tick += 1
                low[w] = low_h[w] = w
                savior[w] = w
                frames.append([w, v, 0])
            elif state[w] == 1 and w != parent and earlier(w, low[v]):
                low[v] = w
                savior[v] = v
            continue

        state[v] = 2
        if parent >= 0:
            if low_h[v] == v:
                add_back_edge(v)
                low_h[v] = low[v]
            if low_h[v] == parent:
                add_back_edge(v)
                low_h[v] = low[v]
                if savior[v] == v:
                    selected[parent_edge[v]] = False
        frames.pop()
        if parent >= 0:
            if earlier(low[v], low[parent]):
                low[parent] = low[v]
                savior[parent] = savior[v]
            if earlier(low_h[v], low_h[parent]):
                low_h[parent] = low_h[v]

    return sorted(edges[eid] for eid, keep in enumerate(selected) if keep)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values):
        return -1, b""
    n, m = values[:2]
    if not 3 <= n <= MAX_N or not 3 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return -1, b""
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for i in range(m):
        u, v = values[2 + 2 * i:4 + 2 * i]
        if not 0 <= u < v < n or (u, v) in seen:
            return -1, b""
        seen.add((u, v))
        edges.append((u, v))
    if not all(_deletion_connected(n, edges, removed) for removed in range(n)):
        return -1, b""
    chosen = _iterative_build(n, edges)
    payload = struct.pack("<" + "q" * (1 + 2 * len(chosen)), len(chosen),
                          *(endpoint for edge in chosen for endpoint in edge))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
