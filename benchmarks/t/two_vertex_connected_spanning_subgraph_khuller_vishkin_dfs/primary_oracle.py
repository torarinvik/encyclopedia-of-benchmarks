"""Recursive clean-room reference for Khuller–Vishkin's §4.1 DFS method."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_M)


def _connected_after_vertex_removal(n: int, edges: list[tuple[int, int]], removed: int) -> bool:
    start = 0 if removed != 0 else 1
    reached = [False] * n
    reached[start] = True
    queue = [start]
    for current in queue:
        for a, b in edges:
            if a == removed or b == removed:
                continue
            nxt = b if a == current else a if b == current else -1
            if nxt >= 0 and not reached[nxt]:
                reached[nxt] = True
                queue.append(nxt)
    return all(vertex == removed or reached[vertex] for vertex in range(n))


def _is_biconnected(n: int, edges: list[tuple[int, int]]) -> bool:
    return all(_connected_after_vertex_removal(n, edges, removed) for removed in range(n))


def _build(n: int, edges: list[tuple[int, int]]) -> list[tuple[int, int]]:
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    edge_id = {edge: index for index, edge in enumerate(edges)}
    for eid, (u, v) in enumerate(edges):
        adjacency[u].append((v, eid))
        adjacency[v].append((u, eid))

    state = [0] * n  # unvisited, discovered, finished
    discovery = [-1] * n
    low = list(range(n))
    low_h = list(range(n))
    savior = list(range(n))
    selected = [False] * len(edges)
    tree_parent_edge = [-1] * n
    tick = 0

    def earlier(a: int, b: int) -> bool:
        return discovery[a] < discovery[b]

    def visit(v: int, parent: int) -> None:
        nonlocal tick
        state[v] = 1
        discovery[v] = tick
        tick += 1
        low[v] = low_h[v] = v
        savior[v] = v
        for w, eid in adjacency[v]:
            if state[w] == 0:
                selected[eid] = True
                tree_parent_edge[w] = eid
                visit(w, v)
                if earlier(low[w], low[v]):
                    low[v] = low[w]
                    savior[v] = savior[w]
                if earlier(low_h[w], low_h[v]):
                    low_h[v] = low_h[w]
            elif state[w] == 1 and w != parent and earlier(w, low[v]):
                low[v] = w
                savior[v] = v
        state[v] = 2
        if parent < 0:
            return

        if low_h[v] == v:
            pair = (savior[v], low[v])
            chosen_eid = edge_id[pair if pair[0] < pair[1] else (pair[1], pair[0])]
            selected[chosen_eid] = True
            low_h[v] = low[v]
        if low_h[v] == parent:
            pair = (savior[v], low[v])
            chosen_eid = edge_id[pair if pair[0] < pair[1] else (pair[1], pair[0])]
            selected[chosen_eid] = True
            low_h[v] = low[v]
            if savior[v] == v:
                selected[tree_parent_edge[v]] = False

    visit(0, -1)
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
    if not _is_biconnected(n, edges):
        return -1, b""
    chosen = _build(n, edges)
    payload = struct.pack("<" + "q" * (1 + 2 * len(chosen)), len(chosen),
                          *(endpoint for edge in chosen for endpoint in edge))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
