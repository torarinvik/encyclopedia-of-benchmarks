"""Lazy binary-heap Dijkstra oracle with immutable distance entries."""

from __future__ import annotations

import heapq
from collections.abc import Sequence

MAX_VERTICES = 64
MAX_EDGES = 256
MAX_HEAP_RECORDS = MAX_EDGES + 1
I64_MAX = (1 << 63) - 1
I64_MIN = -(1 << 63)
WORKSPACE_BYTES = 8192


def _validate(vertices: int, edges: Sequence[Sequence[int]] | None,
              source: int) -> tuple[int, list[tuple[int, int, int]]] | int:
    if (type(vertices) is not int or type(source) is not int
            or not 0 <= vertices <= MAX_VERTICES
            or not 0 <= source <= (1 << 64) - 1
            or not isinstance(edges, (list, tuple)) or len(edges) > MAX_EDGES):
        return -3
    if vertices == 0:
        return (0, []) if source == 0 and not edges else -3
    if source >= vertices:
        return -3
    parsed: list[tuple[int, int, int]] = []
    for edge in edges:
        if (not isinstance(edge, (list, tuple)) or len(edge) != 3
                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                       for value in edge)):
            return -3
        origin, destination, weight = edge
        if not 0 <= origin < vertices or not 0 <= destination < vertices:
            return -3
        if weight < 0:
            return -4
        parsed.append((origin, destination, weight))
    return vertices, parsed


def expected_result(vertices: int, edges: Sequence[Sequence[int]] | None,
                    source: int) -> tuple[int, list[int | None] | None]:
    """Return (status, distances), matching the graph ABI's overflow rule."""
    parsed = _validate(vertices, edges, source)
    if isinstance(parsed, int):
        return parsed, None
    n, arcs = parsed
    if n == 0:
        return 0, []

    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for origin, destination, weight in arcs:
        adjacency[origin].append((destination, weight))

    distance: list[int | None] = [None] * n
    distance[source] = 0
    pending: list[tuple[int, int]] = [(0, source)]
    settled = [False] * n
    while pending:
        current, origin = heapq.heappop(pending)
        if current != distance[origin] or settled[origin]:
            continue
        settled[origin] = True
        for destination, weight in adjacency[origin]:
            if current > I64_MAX - weight:
                return -2, None
            candidate = current + weight
            old = distance[destination]
            if not settled[destination] and (old is None or candidate < old):
                distance[destination] = candidate
                heapq.heappush(pending, (candidate, destination))
    return 0, distance
