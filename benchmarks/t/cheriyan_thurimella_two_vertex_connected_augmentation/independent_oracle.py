"""Exhaustive matching and articulation-search reference for the heuristic."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_PARSEABLE_INPUT_LENGTH = 59


def _read(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(item) is not int or not -(1 << 63) <= item < (1 << 63)
           for item in values):
        return None
    vertex_count, edge_count = values[0], values[1]
    if (not 3 <= vertex_count <= MAX_N or not 3 <= edge_count <= MAX_M
            or len(values) != 2 + 2 * edge_count):
        return None
    records: list[tuple[int, int]] = []
    used: set[tuple[int, int]] = set()
    for record in range(edge_count):
        left, right = values[2 + 2 * record], values[3 + 2 * record]
        if not 0 <= left < right < vertex_count or (left, right) in used:
            return None
        used.add((left, right))
        records.append((left, right))
    return vertex_count, edge_count, records


def _has_articulation(n: int, edges: list[tuple[int, int]], active: list[bool]) -> bool:
    adjacency: list[list[int]] = [[] for _ in range(n)]
    for edge_id, (u, v) in enumerate(edges):
        if active[edge_id]:
            adjacency[u].append(v)
            adjacency[v].append(u)
    discovered = [-1] * n
    low = [0] * n
    tick = 0
    articulation = False

    def visit(vertex: int, parent: int) -> None:
        nonlocal tick, articulation
        discovered[vertex] = low[vertex] = tick
        tick += 1
        children = 0
        for other in adjacency[vertex]:
            if discovered[other] < 0:
                children += 1
                visit(other, vertex)
                low[vertex] = min(low[vertex], low[other])
                if parent >= 0 and low[other] >= discovered[vertex]:
                    articulation = True
            elif other != parent:
                low[vertex] = min(low[vertex], discovered[other])
        if parent < 0 and children > 1:
            articulation = True

    visit(0, -1)
    return articulation or any(value < 0 for value in discovered)


def _first_maximum_matching(n: int, edges: list[tuple[int, int]]) -> list[bool]:
    """Enumerate matching branches in the pinned edge-first order."""
    matching = [False] * len(edges)
    chosen = [False] * len(edges)
    best_size = -1

    def enumerate_matchings(mask: int, size: int) -> None:
        nonlocal best_size, chosen
        if not mask:
            if size > best_size:
                best_size = size
                chosen = matching.copy()
            return
        first_bit = mask & -mask
        first = first_bit.bit_length() - 1
        remainder = mask & ~first_bit
        for edge_id, (u, v) in enumerate(edges):
            if u == first and remainder & (1 << v):
                matching[edge_id] = True
                enumerate_matchings(remainder & ~(1 << v), size + 1)
                matching[edge_id] = False
            elif v == first and remainder & (1 << u):
                matching[edge_id] = True
                enumerate_matchings(remainder & ~(1 << u), size + 1)
                matching[edge_id] = False
        enumerate_matchings(remainder, size)

    enumerate_matchings((1 << n) - 1, 0)
    covered = [False] * n
    for edge_id, selected in enumerate(chosen):
        if selected:
            u, v = edges[edge_id]
            covered[u] = covered[v] = True
    for vertex in range(n):
        if covered[vertex]:
            continue
        for edge_id, (u, v) in enumerate(edges):
            if u == vertex or v == vertex:
                chosen[edge_id] = True
                covered[u] = covered[v] = True
                break
    return chosen


def _build(n: int, edges: list[tuple[int, int]]) -> list[bool]:
    cover = _first_maximum_matching(n, edges)
    active = [True] * len(edges)
    for edge_id in range(len(edges)):
        if cover[edge_id]:
            continue
        active[edge_id] = False
        if _has_articulation(n, edges, active):
            active[edge_id] = True
    return active


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
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    n, m, edges = parsed
    if _has_articulation(n, edges, [True] * m):
        return -1, b""
    active = _build(n, edges)
    chosen = [(u, v) for edge_id, (u, v) in enumerate(edges) if active[edge_id]]
    payload = struct.pack("<" + "q" * (1 + 2 * len(chosen)), len(chosen),
                          *(endpoint for edge in chosen for endpoint in edge))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
