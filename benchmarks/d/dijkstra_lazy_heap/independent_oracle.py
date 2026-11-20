"""Bellman–Ford distance reference with post-pass signed-i64 overflow checks."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import I64_MAX, I64_MIN, MAX_EDGES, MAX_VERTICES


def _validate(vertices: int, edges: Sequence[Sequence[int]] | None,
              source: int):
    # Separate validation flow from the heap-based reference.
    if (type(vertices) is not int or type(source) is not int
            or vertices < 0 or vertices > MAX_VERTICES
            or source < 0 or source > (1 << 64) - 1
            or not isinstance(edges, (list, tuple))):
        return -3
    if vertices == 0:
        if source == 0 and len(edges) == 0:
            return 0, []
        return -3
    if len(edges) > MAX_EDGES or source >= vertices:
        return -3
    arcs = []
    for item in edges:
        if (not isinstance(item, (list, tuple)) or len(item) != 3
                or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                       for value in item)):
            return -3
        u, v, weight = item
        if u < 0 or u >= vertices or v < 0 or v >= vertices:
            return -3
        if weight < 0:
            return -4
        arcs.append((u, v, weight))
    return vertices, arcs


def expected_result(vertices: int, edges: Sequence[Sequence[int]] | None,
                    source: int) -> tuple[int, list[int | None] | None]:
    parsed = _validate(vertices, edges, source)
    if isinstance(parsed, int):
        return parsed, None
    n, arcs = parsed
    if n == 0:
        return 0, []

    # Arbitrary-precision labels let this oracle distinguish a true overflow
    # from a merely large finite prefix without sharing the heap traversal.
    distance: list[int | None] = [None] * n
    distance[source] = 0
    for _ in range(n - 1):
        changed = False
        for u, v, weight in arcs:
            base = distance[u]
            if base is None:
                continue
            candidate = base + weight
            if distance[v] is None or candidate < distance[v]:
                distance[v] = candidate
                changed = True
        if not changed:
            break

    for u, v, weight in arcs:
        base = distance[u]
        if base is not None and base + weight > I64_MAX:
            return -2, None
    return 0, distance
