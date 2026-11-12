"""Independent Euler-characteristic oracle for bounded planar face counts."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_N = 16
MAX_M = 42
MAX_ABS_COORD = 100


def _orient(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _between(a: tuple[int, int], b: tuple[int, int], p: tuple[int, int]) -> bool:
    return min(a[0], b[0]) <= p[0] <= max(a[0], b[0]) and min(a[1], b[1]) <= p[1] <= max(a[1], b[1])


def _intersects(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int], d: tuple[int, int]) -> bool:
    x1, x2 = _orient(a, b, c), _orient(a, b, d)
    y1, y2 = _orient(c, d, a), _orient(c, d, b)
    if ((x1 > 0 > x2) or (x2 > 0 > x1)) and ((y1 > 0 > y2) or (y2 > 0 > y1)):
        return True
    return ((x1 == 0 and _between(a, b, c)) or (x2 == 0 and _between(a, b, d))
            or (y1 == 0 and _between(c, d, a)) or (y2 == 0 and _between(c, d, b)))


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > 118:
        return -1
    if any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values):
        return -1
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return -1
    max_planar_edges = 0 if n == 1 else 1 if n == 2 else 3 * n - 6
    if m > max_planar_edges or len(values) != 2 + 2 * n + 2 * m:
        return -1
    points = [(values[2 + 2 * i], values[3 + 2 * i]) for i in range(n)]
    if len(set(points)) != n or any(abs(x) > MAX_ABS_COORD or abs(y) > MAX_ABS_COORD for x, y in points):
        return -1
    first_edge = 2 + 2 * n
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    adjacency = [[] for _ in range(n)]
    for i in range(m):
        u, v = values[first_edge + 2 * i], values[first_edge + 2 * i + 1]
        if u < 0 or u >= n or v < 0 or v >= n or u == v:
            return -1
        canonical = (min(u, v), max(u, v))
        if canonical in seen:
            return -1
        seen.add(canonical)
        edges.append((u, v))
        adjacency[u].append(v)
        adjacency[v].append(u)
    visited_vertices = [False] * n
    visited_vertices[0] = True
    queue = deque([0])
    while queue:
        u = queue.popleft()
        for v in adjacency[u]:
            if not visited_vertices[v]:
                visited_vertices[v] = True
                queue.append(v)
    if not all(visited_vertices):
        return -1

    for i, (u, v) in enumerate(edges):
        for a, b in edges[i + 1:]:
            common = set((u, v)).intersection((a, b))
            if len(common) == 1:
                center = next(iter(common))
                du = points[v if u == center else u]
                dv = points[b if a == center else a]
                origin = points[center]
                ax, ay = du[0] - origin[0], du[1] - origin[1]
                bx, by = dv[0] - origin[0], dv[1] - origin[1]
                if ax * by == ay * bx and ax * bx + ay * by > 0:
                    return -1
            elif not common and _intersects(points[u], points[v], points[a], points[b]):
                return -1
    return 1 if n == 1 else m - n + 2
