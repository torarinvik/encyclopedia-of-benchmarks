"""Primary bounded oracle for the seeded LR Ring-Expander pass."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 12
MAX_TRIANGLES = 20
MAX_INPUT_LENGTH = 64
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 504
WORKSPACE_BYTES = 8192
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 15 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)):
        return None
    n, t, seed = values[:3]
    if not 4 <= n <= MAX_VERTICES or not 4 <= t <= MAX_TRIANGLES:
        return None
    if len(values) != 3 + 3 * t or not 0 <= seed < 3 * t:
        return None
    triangles = [tuple(values[3 + 3 * k:6 + 3 * k]) for k in range(t)]
    if any(any(v < 0 or v >= n for v in tri) or len(set(tri)) != 3 for tri in triangles):
        return None
    if len({tuple(sorted(tri)) for tri in triangles}) != t:
        return None
    return n, t, seed, triangles


def _operators(n: int, t: int, triangles: list[tuple[int, int, int]]):
    # Corner j is opposite the directed edge (corner j+1, corner j+2).
    edge_corners: dict[tuple[int, int], list[int]] = {}
    link: list[dict[int, set[int]]] = [dict() for _ in range(n)]
    used = [False] * n
    for ti, tri in enumerate(triangles):
        for v in tri:
            used[v] = True
        for j in range(3):
            u = tri[(j + 1) % 3]
            v = tri[(j + 2) % 3]
            edge_corners.setdefault((min(u, v), max(u, v)), []).append(3 * ti + j)
            center = tri[j]
            link[center].setdefault(u, set()).add(v)
            link[center].setdefault(v, set()).add(u)
    if not all(used):
        return None

    opposite = [-1] * (3 * t)
    triangle_neighbors = [[] for _ in range(t)]
    for corners in edge_corners.values():
        if len(corners) != 2:
            return None
        a, b = corners
        ta, ja = divmod(a, 3)
        tb, jb = divmod(b, 3)
        aa = triangles[ta][(ja + 1) % 3], triangles[ta][(ja + 2) % 3]
        bb = triangles[tb][(jb + 1) % 3], triangles[tb][(jb + 2) % 3]
        if aa != bb[::-1]:
            return None
        opposite[a] = b
        opposite[b] = a
        triangle_neighbors[ta].append(tb)
        triangle_neighbors[tb].append(ta)
    if any(value < 0 for value in opposite):
        return None

    for vertex in range(n):
        adjacency = link[vertex]
        if not adjacency or any(len(neighbors) != 2 for neighbors in adjacency.values()):
            return None
        reached = {next(iter(adjacency))}
        todo = list(reached)
        while todo:
            current = todo.pop()
            for other in adjacency[current]:
                if other not in reached:
                    reached.add(other)
                    todo.append(other)
        if len(reached) != len(adjacency):
            return None

    reached_triangles = {0}
    todo = [0]
    while todo:
        current = todo.pop()
        for other in triangle_neighbors[current]:
            if other not in reached_triangles:
                reached_triangles.add(other)
                todo.append(other)
    if len(reached_triangles) != t:
        return None
    return opposite


def _run(n: int, t: int, seed: int, triangles: list[tuple[int, int, int]]):
    opposite = _operators(n, t, triangles)
    if opposite is None:
        return None
    seen_vertices = 0
    seen_triangles = 0
    trace: list[int] = []
    seen_corners: set[int] = set()
    c = seed
    seen_vertices |= 1 << triangles[(c // 3)][(c % 3 + 1) % 3]
    seen_vertices |= 1 << triangles[(c // 3)][(c % 3 + 2) % 3]
    stop = opposite[seed]
    while c != stop:
        if c in seen_corners or len(trace) >= 3 * t:
            return None
        seen_corners.add(c)
        trace.append(c)
        triangle, local = divmod(c, 3)
        vertex = triangles[triangle][local]
        if not (seen_vertices >> vertex) & 1:
            seen_vertices |= 1 << vertex
            seen_triangles |= 1 << triangle
        elif not (seen_triangles >> triangle) & 1:
            c = opposite[c]
        current_triangle, current_local = divmod(c, 3)
        previous = 3 * current_triangle + (current_local + 2) % 3
        c = opposite[previous]
    words = [len(trace), *trace, seen_vertices, seen_triangles]
    return struct.pack("<" + "q" * len(words), *words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    output = _run(*parsed)
    if output is None:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
