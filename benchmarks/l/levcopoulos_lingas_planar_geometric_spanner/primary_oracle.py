"""Bounded clean-room reference for Levcopoulos–Lingas Algorithm 3.1.

The workload's ``carried_path_triggers_retained_shortcut`` fixture first
carries ``sqrt(10) + 3`` onto A-Q, then checks that adding ``sqrt(18)`` exceeds
``2 * |A-B| = 10`` after the fixed stack-order absorptions.
"""
from __future__ import annotations

import math
import struct
from collections.abc import Sequence
from functools import cmp_to_key
from itertools import combinations

MAX_N = 8
MAX_EDGES = 18
MAX_VALID_INPUT_LENGTH = 54
MAX_PARSEABLE_INPUT_LENGTH = 55
MAX_OUTPUT_BYTES = 312
WORKSPACE_BYTES = 8192


def _orient(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _incircle(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int],
              p: tuple[int, int]) -> int:
    ax, ay = a[0] - p[0], a[1] - p[1]
    bx, by = b[0] - p[0], b[1] - p[1]
    cx, cy = c[0] - p[0], c[1] - p[1]
    value = ((ax * ax + ay * ay) * (bx * cy - by * cx)
             - (bx * bx + by * by) * (ax * cy - ay * cx)
             + (cx * cx + cy * cy) * (ax * by - ay * bx))
    return value if _orient(a, b, c) > 0 else -value


def _polar_compare(origin: tuple[int, int], a: int, b: int,
                   points: list[tuple[int, int]]) -> int:
    ax, ay = points[a][0] - origin[0], points[a][1] - origin[1]
    bx, by = points[b][0] - origin[0], points[b][1] - origin[1]
    ah = 0 if ay > 0 or (ay == 0 and ax >= 0) else 1
    bh = 0 if by > 0 or (by == 0 and bx >= 0) else 1
    if ah != bh:
        return -1 if ah < bh else 1
    cross = ax * by - ay * bx
    if cross:
        return -1 if cross > 0 else 1
    return -1 if a < b else 1 if a > b else 0


def _hull(points: list[tuple[int, int]]) -> set[int]:
    order = sorted(range(len(points)), key=lambda i: (points[i][0], points[i][1], i))
    lower: list[int] = []
    for v in order:
        while len(lower) >= 2 and _orient(points[lower[-2]], points[lower[-1]], points[v]) <= 0:
            lower.pop()
        lower.append(v)
    upper: list[int] = []
    for v in reversed(order):
        while len(upper) >= 2 and _orient(points[upper[-2]], points[upper[-1]], points[v]) <= 0:
            upper.pop()
        upper.append(v)
    return set(lower[:-1] + upper[:-1])


def _parse(values: Sequence[int] | None) -> tuple[int, list[tuple[int, int]], list[tuple[int, int]]] | None:
    if (values is None or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if type(n) is not int or not 3 <= n <= MAX_N or len(values) < 2 + 2 * n:
        return None
    points = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(n)]
    if any(not -10 <= x <= 10 or not -10 <= y <= 10 for x, y in points):
        return None
    if len(set(points)) != n:
        return None
    if any(_orient(points[a], points[b], points[c]) == 0
           for a, b, c in combinations(range(n), 3)):
        return None
    if any(_incircle(points[a], points[b], points[c], points[d]) == 0
           for a, b, c, d in combinations(range(n), 4)):
        return None
    m_at = 1 + 2 * n
    m = values[m_at]
    if type(m) is not int or not 3 <= m <= MAX_EDGES or len(values) != m_at + 1 + 2 * m:
        return None
    edges = [(values[m_at + 1 + 2 * i], values[m_at + 2 + 2 * i]) for i in range(m)]
    if (any(not 0 <= u < v < n for u, v in edges)
            or edges != sorted(set(edges))):
        return None

    faces: list[tuple[int, int, int]] = []
    for a, b, c in combinations(range(n), 3):
        if _orient(points[a], points[b], points[c]) < 0:
            a, b = b, a
        if all(_incircle(points[a], points[b], points[c], points[p]) < 0
               for p in range(n) if p not in (a, b, c)):
            faces.append(tuple(sorted((a, b, c))))
    expected_edges = sorted({(min(u, v), max(u, v))
                             for a, b, c in faces
                             for u, v in ((a, b), (b, c), (a, c))})
    if edges != expected_edges:
        return None
    return n, points, edges


def _construct(n: int, points: list[tuple[int, int]],
               edges: list[tuple[int, int]]) -> tuple[int, int, list[tuple[int, int]]] | None:
    faces: set[tuple[int, int, int]] = set()
    for a, b, c in combinations(range(n), 3):
        if not all((min(u, v), max(u, v)) in edges
                   for u, v in ((a, b), (b, c), (a, c))):
            continue
        if _orient(points[a], points[b], points[c]) < 0:
            a, b = b, a
        if all(_incircle(points[a], points[b], points[c], points[p]) < 0
               for p in range(n) if p not in (a, b, c)):
            faces.add(tuple(sorted((a, b, c))))

    parent = list(range(n))
    size = [1] * n

    def find(v: int) -> int:
        while parent[v] != v:
            parent[v] = parent[parent[v]]
            v = parent[v]
        return v

    tree: list[tuple[int, int]] = []
    for u, v in sorted(edges, key=lambda e: ((points[e[0]][0] - points[e[1]][0]) ** 2
                                             + (points[e[0]][1] - points[e[1]][1]) ** 2,
                                             e[0], e[1])):
        ru, rv = find(u), find(v)
        if ru != rv:
            if size[ru] < size[rv]:
                ru, rv = rv, ru
            parent[rv] = ru
            size[ru] += size[rv]
            tree.append((u, v))
    if len(tree) != n - 1:
        return None

    rotation: list[list[int]] = [[] for _ in range(n)]
    tree_rotation: list[list[int]] = [[] for _ in range(n)]
    for u, v in edges:
        rotation[u].append(v)
        rotation[v].append(u)
    for u, v in tree:
        tree_rotation[u].append(v)
        tree_rotation[v].append(u)
    for v in range(n):
        rotation[v].sort(key=cmp_to_key(lambda a, b: _polar_compare(points[v], a, b, points)))
        tree_rotation[v].sort(key=cmp_to_key(lambda a, b: _polar_compare(points[v], a, b, points)))

    def cw_next(dart: tuple[int, int]) -> tuple[int, int]:
        u, v = dart
        around = rotation[v]
        at = around.index(u)
        return v, around[(at - 1) % len(around)]

    def cw_tree_next(dart: tuple[int, int]) -> tuple[int, int]:
        u, v = dart
        around = tree_rotation[v]
        at = around.index(u)
        return v, around[(at - 1) % len(around)]

    if not tree:
        return None
    first = min([(u, v) for a, b in tree for u, v in ((a, b), (b, a))])
    contour = [first]
    while True:
        nxt = cw_tree_next(contour[-1])
        if nxt == first:
            break
        if nxt in contour or len(contour) >= 2 * (n - 1):
            return None
        contour.append(nxt)
    if len(contour) != 2 * (n - 1):
        return None

    hull = _hull(points)
    weights = {(u, v): math.sqrt((points[u][0] - points[v][0]) ** 2
                                 + (points[u][1] - points[v][1]) ** 2)
               for a, b in edges for u, v in ((a, b), (b, a))}
    kept = set(tree)
    absorbed = 0
    stack: list[tuple[int, int]] = []

    def canonicalize() -> None:
        if contour:
            start = min(range(len(contour)), key=lambda i: contour[i])
            contour[:] = contour[start:] + contour[:start]

    def eligible(dart: tuple[int, int]) -> bool:
        try:
            index = contour.index(dart)
        except ValueError:
            return False
        if dart[1] in hull or len(contour) < 3:
            return False
        following = contour[(index + 1) % len(contour)]
        return following == cw_next(dart) and tuple(sorted((dart[0], dart[1], following[1]))) in faces

    canonicalize()
    for dart in contour:
        if eligible(dart):
            stack.append(dart)
    max_steps = 2 * MAX_EDGES
    while stack and absorbed < max_steps:
        dart = stack.pop()
        if not eligible(dart):
            continue
        index = contour.index(dart)
        following_index = (index + 1) % len(contour)
        next_dart = contour[following_index]
        v, w = dart
        if next_dart[0] != w:
            return None
        u = next_dart[1]
        shortcut = (v, u)
        face = tuple(sorted((v, w, u)))
        if face not in faces:
            return None
        path_weight = weights[dart] + weights[next_dart]
        chord_length = math.sqrt((points[v][0] - points[u][0]) ** 2
                                 + (points[v][1] - points[u][1]) ** 2)
        if path_weight > 2.0 * chord_length:
            kept.add((min(v, u), max(v, u)))
        else:
            weights[shortcut] = path_weight

        if following_index == 0:
            contour.pop(index)
            contour.pop(0)
            contour.append(shortcut)
        else:
            contour[index:following_index + 1] = [shortcut]
        canonicalize()
        absorbed += 1

        new_index = contour.index(shortcut)
        right = shortcut
        if eligible(right):
            stack.append(right)
        left = contour[(new_index - 1) % len(contour)]
        if eligible(left):
            stack.append(left)

    if absorbed >= max_steps:
        return None
    return absorbed, len(kept) - (n - 1), sorted(kept)


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
    n, points, edges = parsed
    result = _construct(n, points, edges)
    if result is None:
        return -1, b""
    absorbed, shortcuts, retained = result
    words = [absorbed, shortcuts, len(retained)]
    words.extend(endpoint for edge in retained for endpoint in edge)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
