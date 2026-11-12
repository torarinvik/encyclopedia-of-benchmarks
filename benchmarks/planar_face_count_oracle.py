"""Polar-order half-edge traversal for bounded planar face counting."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence
from functools import cmp_to_key

MAX_VERTICES = 16
MAX_EDGES = 42
MAX_COORDINATE = 100
MAX_INPUT_LENGTH = 2 + 2 * MAX_VERTICES + 2 * MAX_EDGES


def _cross(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _on_segment(a: tuple[int, int], b: tuple[int, int], p: tuple[int, int]) -> bool:
    return (min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _segments_intersect(a: tuple[int, int], b: tuple[int, int],
                        c: tuple[int, int], d: tuple[int, int]) -> bool:
    ab_c, ab_d = _cross(a, b, c), _cross(a, b, d)
    cd_a, cd_b = _cross(c, d, a), _cross(c, d, b)
    if ((ab_c > 0 and ab_d < 0) or (ab_c < 0 and ab_d > 0)) and (
        (cd_a > 0 and cd_b < 0) or (cd_a < 0 and cd_b > 0)
    ):
        return True
    return ((ab_c == 0 and _on_segment(a, b, c))
            or (ab_d == 0 and _on_segment(a, b, d))
            or (cd_a == 0 and _on_segment(c, d, a))
            or (cd_b == 0 and _on_segment(c, d, b)))


def _read(values: Sequence[int] | None) -> tuple[list[tuple[int, int]], list[tuple[int, int]], list[list[int]]] | None:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    planar_edge_cap = 0 if n == 1 else 1 if n == 2 else 3 * n - 6
    if m > planar_edge_cap or len(values) != 2 + 2 * n + 2 * m:
        return None
    points = [(values[2 + 2 * i], values[3 + 2 * i]) for i in range(n)]
    if any(abs(x) > MAX_COORDINATE or abs(y) > MAX_COORDINATE for x, y in points):
        return None
    if len(set(points)) != n:
        return None
    edges: list[tuple[int, int]] = []
    adjacency = [[] for _ in range(n)]
    edge_set: set[tuple[int, int]] = set()
    offset = 2 + 2 * n
    for i in range(m):
        u, v = values[offset + 2 * i], values[offset + 2 * i + 1]
        if not (0 <= u < n and 0 <= v < n) or u == v:
            return None
        edge = (min(u, v), max(u, v))
        if edge in edge_set:
            return None
        edge_set.add(edge)
        edges.append((u, v))
        adjacency[u].append(v)
        adjacency[v].append(u)

    reached = {0}
    queue = deque([0])
    while queue:
        u = queue.popleft()
        for v in adjacency[u]:
            if v not in reached:
                reached.add(v)
                queue.append(v)
    if len(reached) != n:
        return None

    for i, (u, v) in enumerate(edges):
        for a, b in edges[i + 1:]:
            shared = {u, v} & {a, b}
            if len(shared) == 1:
                common = next(iter(shared))
                other_u = v if u == common else u
                other_a = b if a == common else a
                p = points[common]
                du = (points[other_u][0] - p[0], points[other_u][1] - p[1])
                da = (points[other_a][0] - p[0], points[other_a][1] - p[1])
                if du[0] * da[1] == du[1] * da[0] and du[0] * da[0] + du[1] * da[1] > 0:
                    return None
            elif not shared and _segments_intersect(points[u], points[v], points[a], points[b]):
                return None
    return points, edges, adjacency


def _angle_half(origin: tuple[int, int], point: tuple[int, int]) -> int:
    dx, dy = point[0] - origin[0], point[1] - origin[1]
    return 0 if dy > 0 or (dy == 0 and dx >= 0) else 1


def _neighbor_compare(points: list[tuple[int, int]], origin: int, a: int, b: int) -> int:
    pa, pb, center = points[a], points[b], points[origin]
    ha, hb = _angle_half(center, pa), _angle_half(center, pb)
    if ha != hb:
        return -1 if ha < hb else 1
    cross = ((pa[0] - center[0]) * (pb[1] - center[1])
             - (pa[1] - center[1]) * (pb[0] - center[0]))
    return -1 if cross > 0 else 1 if cross < 0 else 0


def expected_result(values: Sequence[int] | None) -> int:
    parsed = _read(values)
    if parsed is None:
        return -1
    points, edges, adjacency = parsed
    n = len(points)
    if n == 1:
        return 1
    ordered = [sorted(adjacency[u], key=cmp_to_key(
        lambda a, b, origin=u: _neighbor_compare(points, origin, a, b))) for u in range(n)]
    visited = [[False] * n for _ in range(n)]
    faces = 0
    for u, v in edges:
        for start_u, start_v in ((u, v), (v, u)):
            if visited[start_u][start_v]:
                continue
            faces += 1
            cur_u, cur_v = start_u, start_v
            steps = 0
            while not visited[cur_u][cur_v]:
                visited[cur_u][cur_v] = True
                around = ordered[cur_v]
                reverse_index = around.index(cur_u)
                nxt = around[(reverse_index + 1) % len(around)]
                cur_u, cur_v = cur_v, nxt
                steps += 1
                if steps > 2 * len(edges):
                    return -1
    return faces
