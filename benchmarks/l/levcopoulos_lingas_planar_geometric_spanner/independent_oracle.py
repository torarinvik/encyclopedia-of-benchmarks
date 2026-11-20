"""Independent bounded face-event reference for the LL pruning profile.

The workload's ``carried_path_triggers_retained_shortcut`` fixture checks the
strict threshold through face events: A-Q carries ``sqrt(10) + 3``, and the
later A-Q-B path has weight ``sqrt(10) + 3 + sqrt(18) > 10``.
"""
from __future__ import annotations

import math
import struct
from collections.abc import Sequence
from itertools import combinations

MAX_N = 8
MAX_EDGES = 18
MAX_VALID_INPUT_LENGTH = 54
MAX_PARSEABLE_INPUT_LENGTH = 55
MAX_OUTPUT_BYTES = 312
WORKSPACE_BYTES = 8192


def _cross(o: tuple[int, int], a: tuple[int, int], b: tuple[int, int]) -> int:
    return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])


def _circle_side(p: tuple[int, int], a: tuple[int, int], b: tuple[int, int],
                 c: tuple[int, int]) -> int:
    ax, ay = a[0] - p[0], a[1] - p[1]
    bx, by = b[0] - p[0], b[1] - p[1]
    cx, cy = c[0] - p[0], c[1] - p[1]
    det = ((ax * ax + ay * ay) * (bx * cy - by * cx)
           + (bx * bx + by * by) * (cx * ay - cy * ax)
           + (cx * cx + cy * cy) * (ax * by - ay * bx))
    orientation = _cross(a, b, c)
    return det if orientation > 0 else -det


def _faces_from_empty_disks(points: list[tuple[int, int]]) -> set[tuple[int, int, int]]:
    faces: set[tuple[int, int, int]] = set()
    for triple in combinations(range(len(points)), 3):
        a, b, c = triple
        if _cross(points[a], points[b], points[c]) == 0:
            return set()
        if all(_circle_side(points[p], points[a], points[b], points[c]) < 0
               for p in range(len(points)) if p not in triple):
            faces.add(triple)
    return faces


def _unpack(values: Sequence[int] | None):
    if (values is None or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if type(n) is not int or not 3 <= n <= MAX_N or len(values) < 2 + 2 * n:
        return None
    points = [(values[1 + 2 * v], values[2 + 2 * v]) for v in range(n)]
    if (any(not -10 <= x <= 10 or not -10 <= y <= 10 for x, y in points)
            or len(set(points)) != n):
        return None
    for triple in combinations(range(n), 3):
        if _cross(points[triple[0]], points[triple[1]], points[triple[2]]) == 0:
            return None
    for four in combinations(range(n), 4):
        a, b, c = four[:3]
        if _circle_side(points[four[3]], points[a], points[b], points[c]) == 0:
            return None
    start = 1 + 2 * n
    m = values[start]
    if type(m) is not int or not 3 <= m <= MAX_EDGES or len(values) != start + 1 + 2 * m:
        return None
    edges = [(values[start + 1 + 2 * i], values[start + 2 + 2 * i]) for i in range(m)]
    if (any(not 0 <= a < b < n for a, b in edges)
            or any(edges[i - 1] >= edges[i] for i in range(1, len(edges)))):
        return None
    faces = _faces_from_empty_disks(points)
    edge_union = {tuple(sorted(pair)) for face in faces
                  for pair in ((face[0], face[1]), (face[0], face[2]), (face[1], face[2]))}
    if set(edges) != edge_union:
        return None
    return n, points, edges, faces


def _hull_vertices(points: list[tuple[int, int]]) -> set[int]:
    order = sorted(range(len(points)), key=lambda i: (points[i][0], points[i][1]))
    lower: list[int] = []
    for vertex in order:
        while len(lower) >= 2 and _cross(points[lower[-2]], points[lower[-1]], points[vertex]) <= 0:
            lower.pop()
        lower.append(vertex)
    upper: list[int] = []
    for vertex in reversed(order):
        while len(upper) >= 2 and _cross(points[upper[-2]], points[upper[-1]], points[vertex]) <= 0:
            upper.pop()
        upper.append(vertex)
    return set(lower[:-1] + upper[:-1])


def _tree_by_kruskal(n: int, points: list[tuple[int, int]], edges: list[tuple[int, int]]):
    roots = list(range(n))

    def root(v: int) -> int:
        while roots[v] != v:
            roots[v] = roots[roots[v]]
            v = roots[v]
        return v

    chosen: list[tuple[int, int]] = []
    ordered = sorted(edges, key=lambda e: ((points[e[0]][0] - points[e[1]][0]) ** 2
                                           + (points[e[0]][1] - points[e[1]][1]) ** 2,
                                           e[0], e[1]))
    for a, b in ordered:
        ra, rb = root(a), root(b)
        if ra != rb:
            roots[rb] = ra
            chosen.append((a, b))
    return chosen


def _sort_by_angle(vertex: int, neighbors: list[int], points: list[tuple[int, int]]) -> list[int]:
    ox, oy = points[vertex]

    def key(neighbor: int):
        dx, dy = points[neighbor][0] - ox, points[neighbor][1] - oy
        return math.atan2(dy, dx)

    # The bounded integer domain has no collinear triples, so atan2 has no ties
    # except a point on the same ray, which strict general position excludes.
    return sorted(neighbors, key=key)


def _solve(n: int, points: list[tuple[int, int]], edges: list[tuple[int, int]],
           faces: set[tuple[int, int, int]]):
    tree = _tree_by_kruskal(n, points, edges)
    full = [[] for _ in range(n)]
    adjacency = [[] for _ in range(n)]
    for a, b in edges:
        full[a].append(b)
        full[b].append(a)
    for a, b in tree:
        adjacency[a].append(b)
        adjacency[b].append(a)
    for v in range(n):
        full[v] = _sort_by_angle(v, full[v], points)
        adjacency[v] = _sort_by_angle(v, adjacency[v], points)

    def clockwise(dart: tuple[int, int]) -> tuple[int, int]:
        a, b = dart
        around = full[b]
        return b, around[(around.index(a) - 1) % len(around)]

    def tree_clockwise(dart: tuple[int, int]) -> tuple[int, int]:
        a, b = dart
        around = adjacency[b]
        return b, around[(around.index(a) - 1) % len(around)]

    darts = sorted((a, b) for u, v in tree for a, b in ((u, v), (v, u)))
    seed = darts[0]
    boundary = [seed]
    while True:
        nxt = tree_clockwise(boundary[-1])
        if nxt == seed:
            break
        if nxt in boundary or len(boundary) >= 2 * (n - 1):
            return None
        boundary.append(nxt)

    hull = _hull_vertices(points)
    accumulated = {(a, b): math.sqrt((points[a][0] - points[b][0]) ** 2
                                     + (points[a][1] - points[b][1]) ** 2)
                   for x, y in edges for a, b in ((x, y), (y, x))}
    included = set(tree)
    face_events: list[tuple[int, int, int]] = []

    def canonicalize() -> None:
        if boundary:
            shift = min(range(len(boundary)), key=lambda i: boundary[i])
            boundary[:] = boundary[shift:] + boundary[:shift]

    def is_face(a: int, b: int, c: int) -> bool:
        return tuple(sorted((a, b, c))) in faces

    def active_corner(a: int, b: int, c: int) -> bool:
        if b in hull or not is_face(a, b, c):
            return False
        for i, dart in enumerate(boundary):
            if dart == (a, b) and boundary[(i + 1) % len(boundary)] == (b, c):
                return True
        return False

    canonicalize()
    for i, (a, b) in enumerate(boundary):
        c = boundary[(i + 1) % len(boundary)][1]
        if active_corner(a, b, c):
            face_events.append((a, b, c))

    absorbed = 0
    retained_shortcuts = 0
    limit = 2 * MAX_EDGES
    while face_events and absorbed < limit:
        a, b, c = face_events.pop()
        if not active_corner(a, b, c):
            continue
        i = boundary.index((a, b))
        j = (i + 1) % len(boundary)
        chord = (a, c)
        total = accumulated[(a, b)] + accumulated[(b, c)]
        direct = math.sqrt((points[a][0] - points[c][0]) ** 2
                           + (points[a][1] - points[c][1]) ** 2)
        if total > 2.0 * direct:
            edge = (min(a, c), max(a, c))
            if edge not in included:
                retained_shortcuts += 1
            included.add(edge)
        else:
            accumulated[chord] = total
        if j == 0:
            boundary.pop(i)
            boundary.pop(0)
            boundary.append(chord)
        else:
            boundary[i:j + 1] = [chord]
        canonicalize()
        absorbed += 1

        pos = boundary.index(chord)
        right = chord
        after = boundary[(pos + 1) % len(boundary)]
        right_event = (right[0], right[1], after[1])
        if active_corner(*right_event):
            face_events.append(right_event)
        before = boundary[(pos - 1) % len(boundary)]
        left_event = (before[0], before[1], chord[0])
        if active_corner(*left_event):
            face_events.append(left_event)
    if absorbed >= limit:
        return None
    return absorbed, retained_shortcuts, sorted(included)


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
    parsed = _unpack(values)
    if parsed is None:
        return -1, b""
    result = _solve(*parsed)
    if result is None:
        return -1, b""
    absorbed, shortcuts, retained = result
    words = [absorbed, shortcuts, len(retained)]
    words.extend(value for pair in retained for value in pair)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
