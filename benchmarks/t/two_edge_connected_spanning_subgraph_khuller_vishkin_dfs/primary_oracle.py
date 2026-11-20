"""Recursive clean-room reference for Khuller–Vishkin's DFS 2-ECSS method."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_M)


def _connected(n: int, edges: list[tuple[int, int]], skip: int = -1) -> bool:
    reached = [False] * n
    reached[0] = True
    queue = [0]
    for at in queue:
        for eid, (u, v) in enumerate(edges):
            if eid == skip:
                continue
            nxt = v if u == at else u if v == at else -1
            if nxt >= 0 and not reached[nxt]:
                reached[nxt] = True
                queue.append(nxt)
    return all(reached)


def _valid_graph(n: int, edges: list[tuple[int, int]]) -> bool:
    return _connected(n, edges) and all(_connected(n, edges, eid) for eid in range(len(edges)))


def _build(n: int, edges: list[tuple[int, int]]) -> list[tuple[int, int]]:
    state = [0] * n  # 0 unvisited, 1 active, 2 finished
    disc = [-1] * n
    low = list(range(n))
    low_h = list(range(n))
    savior = list(range(n))
    selected = [False] * len(edges)
    tick = 0

    def earlier(a: int, b: int) -> bool:
        return disc[a] < disc[b]

    def visit(v: int, parent: int) -> None:
        nonlocal tick
        state[v] = 1
        disc[v] = tick
        tick += 1
        low[v] = low_h[v] = v
        savior[v] = v
        # Scanning the original record sequence pins adjacency iteration order.
        for eid, (a, b) in enumerate(edges):
            if a == v:
                w = b
            elif b == v:
                w = a
            else:
                continue
            if state[w] == 0:
                selected[eid] = True
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
        if parent >= 0 and low_h[v] == v:
            a, b = savior[v], low[v]
            pair = (a, b) if a < b else (b, a)
            for eid, edge in enumerate(edges):
                if edge == pair:
                    selected[eid] = True
                    break
            low_h[v] = low[v]

    visit(0, -1)
    return sorted(edges[eid] for eid, keep in enumerate(selected) if keep)


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
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH or any(
            type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
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
    if not _valid_graph(n, edges):
        return -1, b""
    chosen = _build(n, edges)
    payload = struct.pack("<" + "q" * (1 + 2 * len(chosen)), len(chosen),
                          *(x for edge in chosen for x in edge))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
