"""Brute-force Delaunay-edge oracle and independent MST certificate checker."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_POINTS = 8
COORD_LIMIT = 10
MAX_INPUT_LENGTH = 1 + 2 * MAX_POINTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 * MAX_POINTS - 1)
INVALID_RESULT = -1
OUTPUT_ERROR = -2

Point = tuple[int, int]


def _orientation(a: Point, b: Point, c: Point) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _incircle(a: Point, b: Point, c: Point, d: Point) -> int:
    ax, ay = a[0] - d[0], a[1] - d[1]
    bx, by = b[0] - d[0], b[1] - d[1]
    cx, cy = c[0] - d[0], c[1] - d[1]
    return ((ax * ax + ay * ay) * (bx * cy - by * cx)
            - (bx * bx + by * by) * (ax * cy - ay * cx)
            + (cx * cx + cy * cy) * (ax * by - ay * bx))


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> list[Point] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    point_count = values[0]
    if not 1 <= point_count <= MAX_POINTS or len(values) != 1 + 2 * point_count:
        return None
    points = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(point_count)]
    if any(abs(x) > COORD_LIMIT or abs(y) > COORD_LIMIT for x, y in points):
        return None
    if len(set(points)) != point_count:
        return None
    for a in range(point_count):
        for b in range(a + 1, point_count):
            for c in range(b + 1, point_count):
                if _orientation(points[a], points[b], points[c]) == 0:
                    return None
                for d in range(point_count):
                    if d != a and d != b and d != c and _incircle(
                        points[a], points[b], points[c], points[d]
                    ) == 0:
                        return None
    return points


def _delaunay_candidates(points: Sequence[Point]) -> list[tuple[int, int]]:
    count = len(points)
    candidates: set[tuple[int, int]] = set()
    if count == 2:
        return [(0, 1)]
    for a in range(count):
        for b in range(a + 1, count):
            for c in range(b + 1, count):
                orientation = _orientation(points[a], points[b], points[c])
                empty = True
                for d in range(count):
                    if d == a or d == b or d == c:
                        continue
                    determinant = _incircle(points[a], points[b], points[c], points[d])
                    if (determinant > 0) == (orientation > 0):
                        empty = False
                        break
                if empty:
                    candidates.add((a, b))
                    candidates.add((a, c))
                    candidates.add((b, c))
    return sorted(candidates)


def _canonical_tree(points: Sequence[Point]) -> list[int]:
    count = len(points)
    candidates = _delaunay_candidates(points)
    edges = sorted(
        ((points[u][0] - points[v][0]) ** 2 + (points[u][1] - points[v][1]) ** 2, u, v)
        for u, v in candidates
    )
    parent = list(range(count))
    size = [1] * count

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    selected: list[int] = []
    for _weight, u, v in edges:
        left, right = find(u), find(v)
        if left != right:
            if size[left] < size[right]:
                left, right = right, left
            parent[right] = left
            size[left] += size[right]
            selected.extend((u, v))
            if len(selected) == 2 * (count - 1):
                break
    return [count - 1, *selected]


def validate_output(values: Sequence[int] | None, payload: bytes) -> bool:
    points = _parse(values, None, False)
    if points is None or not isinstance(payload, (bytes, bytearray)):
        return False
    count = len(points)
    word_count = 1 + 2 * (count - 1)
    if len(payload) != 8 * word_count:
        return False
    words = struct.unpack("<" + "q" * word_count, payload)
    if words[0] != count - 1:
        return False
    parent = list(range(count))
    size = [1] * count
    tree: list[list[tuple[int, int]]] = [[] for _ in points]
    selected: set[tuple[int, int]] = set()

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    for offset in range(1, word_count, 2):
        u, v = words[offset], words[offset + 1]
        if not (0 <= u < count and 0 <= v < count and u != v):
            return False
        edge = (min(u, v), max(u, v))
        if edge in selected:
            return False
        selected.add(edge)
        left, right = find(u), find(v)
        if left == right:
            return False
        if size[left] < size[right]:
            left, right = right, left
        parent[right] = left
        size[left] += size[right]
        dx, dy = points[u][0] - points[v][0], points[u][1] - points[v][1]
        weight = dx * dx + dy * dy
        tree[u].append((v, weight))
        tree[v].append((u, weight))
    root = find(0)
    if any(find(vertex) != root for vertex in range(count)):
        return False

    for source in range(count):
        stack = [(source, -1, 0)]
        path_max = [0] * count
        while stack:
            vertex, previous, maximum = stack.pop()
            path_max[vertex] = maximum
            for neighbor, weight in tree[vertex]:
                if neighbor != previous:
                    stack.append((neighbor, vertex, max(maximum, weight)))
        for target in range(source + 1, count):
            if (source, target) not in selected:
                dx = points[source][0] - points[target][0]
                dy = points[source][1] - points[target][1]
                if path_max[target] > dx * dx + dy * dy:
                    return False
    return True


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    points = _parse(values, input_length, input_is_null)
    if points is None:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    words = _canonical_tree(points)
    payload = struct.pack("<" + "q" * len(words), *words)
    if not validate_output(values, payload):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(payload)):
        return OUTPUT_ERROR, b""
    return len(payload), payload
