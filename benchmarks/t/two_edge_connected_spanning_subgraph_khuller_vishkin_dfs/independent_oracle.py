"""Iterative event-stack reference with an independent bridge precheck."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_PARSEABLE_INPUT_LENGTH = 59


def _has_bridge(n: int, edges: list[tuple[int, int]]) -> bool:
    adj: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for eid, (u, v) in enumerate(edges):
        adj[u].append((v, eid))
        adj[v].append((u, eid))
    disc = [-1] * n
    low = [0] * n
    tick = 0
    bridge = False

    def dfs(v: int, parent_edge: int) -> None:
        nonlocal tick, bridge
        disc[v] = low[v] = tick
        tick += 1
        for w, eid in adj[v]:
            if eid == parent_edge:
                continue
            if disc[w] < 0:
                dfs(w, eid)
                low[v] = min(low[v], low[w])
                if low[w] > disc[v]:
                    bridge = True
            else:
                low[v] = min(low[v], disc[w])

    dfs(0, -1)
    return bridge or any(value < 0 for value in disc)


def _iterative_build(n: int, edges: list[tuple[int, int]]) -> list[tuple[int, int]]:
    state = [0] * n
    disc = [-1] * n
    low = list(range(n))
    low_h = list(range(n))
    savior = list(range(n))
    selected = [False] * len(edges)
    tick = 0
    state[0] = 1
    disc[0] = tick
    tick += 1
    frames: list[list[int]] = [[0, -1, 0]]  # vertex, parent, next edge record

    def earlier(a: int, b: int) -> bool:
        return disc[a] < disc[b]

    while frames:
        v, parent, cursor = frames[-1]
        if cursor < len(edges):
            frames[-1][2] += 1
            eid = cursor
            a, b = edges[eid]
            if a == v:
                w = b
            elif b == v:
                w = a
            else:
                continue
            if state[w] == 0:
                selected[eid] = True
                state[w] = 1
                disc[w] = tick
                tick += 1
                low[w] = low_h[w] = w
                savior[w] = w
                frames.append([w, v, 0])
            elif state[w] == 1 and w != parent and earlier(w, low[v]):
                low[v] = w
                savior[v] = v
            continue

        state[v] = 2
        if parent >= 0 and low_h[v] == v:
            p = (savior[v], low[v])
            pair = p if p[0] < p[1] else (p[1], p[0])
            for eid, edge in enumerate(edges):
                if edge == pair:
                    selected[eid] = True
                    break
            low_h[v] = low[v]
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
    if _has_bridge(n, edges):
        return -1, b""
    chosen = _iterative_build(n, edges)
    payload = struct.pack("<" + "q" * (1 + 2 * len(chosen)), len(chosen),
                          *(x for edge in chosen for x in edge))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
