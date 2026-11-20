"""Bounded DP reference for Cheriyan–Thurimella's two-step heuristic."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_M)


def _parse(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[:2]
    if not 3 <= n <= MAX_N or not 3 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for index in range(m):
        edge = (values[2 + 2 * index], values[3 + 2 * index])
        if not 0 <= edge[0] < edge[1] < n or edge in seen:
            return None
        seen.add(edge)
        edges.append(edge)
    return n, m, edges


def _connected_without_vertex(n: int, edges: list[tuple[int, int]],
                              active: list[bool], removed: int) -> bool:
    start = 0 if removed != 0 else 1
    seen = [False] * n
    seen[start] = True
    queue = [start]
    for current in queue:
        for edge_id, (u, v) in enumerate(edges):
            if not active[edge_id] or u == removed or v == removed:
                continue
            other = v if u == current else u if v == current else -1
            if other >= 0 and not seen[other]:
                seen[other] = True
                queue.append(other)
    return all(vertex == removed or seen[vertex] for vertex in range(n))


def _is_biconnected(n: int, edges: list[tuple[int, int]], active: list[bool]) -> bool:
    return all(_connected_without_vertex(n, edges, active, removed)
               for removed in range(n))


def _edge_cover(n: int, edges: list[tuple[int, int]]) -> list[bool]:
    """DP maximum matching; input-order edge choices break equal optima."""
    limit = 1 << n
    best = [0] * limit
    choice = [-1] * limit
    for mask in range(1, limit):
        first = (mask & -mask).bit_length() - 1
        for edge_id, (u, v) in enumerate(edges):
            if u == first and mask & (1 << v):
                candidate = 1 + best[mask & ~(1 << u) & ~(1 << v)]
            elif v == first and mask & (1 << u):
                candidate = 1 + best[mask & ~(1 << u) & ~(1 << v)]
            else:
                continue
            if candidate > best[mask]:
                best[mask] = candidate
                choice[mask] = edge_id
        skip = best[mask & ~(1 << first)]
        if skip > best[mask]:
            best[mask] = skip
            choice[mask] = -1

    matching = [False] * len(edges)
    covered = [False] * n
    mask = limit - 1
    while mask:
        first = (mask & -mask).bit_length() - 1
        edge_id = choice[mask]
        if edge_id < 0:
            mask &= ~(1 << first)
            continue
        u, v = edges[edge_id]
        matching[edge_id] = True
        covered[u] = covered[v] = True
        mask &= ~(1 << u) & ~(1 << v)

    # A maximum matching has no edge between two uncovered vertices.
    for vertex in range(n):
        if covered[vertex]:
            continue
        for edge_id, (u, v) in enumerate(edges):
            if u == vertex or v == vertex:
                matching[edge_id] = True
                covered[u] = covered[v] = True
                break
    return matching


def _build(n: int, edges: list[tuple[int, int]]) -> list[bool]:
    minimum_edge_cover = _edge_cover(n, edges)
    active = [True] * len(edges)
    for edge_id in range(len(edges)):
        if minimum_edge_cover[edge_id]:
            continue
        active[edge_id] = False
        if not _is_biconnected(n, edges, active):
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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, m, edges = parsed
    if not _is_biconnected(n, edges, [True] * m):
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
