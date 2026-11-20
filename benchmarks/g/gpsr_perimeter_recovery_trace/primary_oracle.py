"""Exact bounded GPSR perimeter-recovery trace reference."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from math import gcd

MAX_N = 8
MAX_M = 18
MAX_VALID_INPUT_LENGTH = 56
MAX_PARSEABLE_INPUT_LENGTH = 57
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_INPUT = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 896
WORKSPACE_BYTES = 8192


def _cross(ax: int, ay: int, bx: int, by: int) -> int:
    return ax * by - ay * bx


def _orient(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return _cross(b[0] - a[0], b[1] - a[1], c[0] - a[0], c[1] - a[1])


def _half(dx: int, dy: int) -> int:
    return 0 if dy > 0 or (dy == 0 and dx >= 0) else 1


def _ccw_less(a: tuple[int, int, int], b: tuple[int, int, int]) -> bool:
    ha = _half(a[0], a[1])
    hb = _half(b[0], b[1])
    if ha != hb:
        return ha < hb
    turn = _cross(a[0], a[1], b[0], b[1])
    if turn != 0:
        return turn > 0
    return a[2] < b[2]


def _proper_intersection_parameter(p: tuple[int, int], q: tuple[int, int],
                                   a: tuple[int, int], b: tuple[int, int]):
    """Return reduced t for p+t(q-p) at a proper segment crossing, else None."""
    rx, ry = q[0] - p[0], q[1] - p[1]
    sx, sy = b[0] - a[0], b[1] - a[1]
    den = _cross(rx, ry, sx, sy)
    if den == 0:
        return None
    ax, ay = a[0] - p[0], a[1] - p[1]
    tn = _cross(ax, ay, sx, sy)
    un = _cross(ax, ay, rx, ry)
    if den < 0:
        den, tn, un = -den, -tn, -un
    if not (0 < tn < den and 0 < un < den):
        return None
    divisor = gcd(tn, den)
    return tn // divisor, den // divisor


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or
            not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH or
            any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                for value in values)):
        return None
    n, m, source, target = values[:4]
    if not 3 <= n <= MAX_N or not n - 1 <= m <= min(MAX_M, 3 * n - 6):
        return None
    if not (0 <= source < n and 0 <= target < n and source != target):
        return None
    if len(values) != 4 + 2 * n + 2 * m:
        return None
    xs = list(values[4:4 + n])
    ys = list(values[4 + n:4 + 2 * n])
    if any(not -16 <= z <= 16 for z in xs + ys):
        return None
    points = list(zip(xs, ys))
    if len(set(points)) != n:
        return None
    # General position avoids ambiguous rotations and line-through-vertex events.
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                if _orient(points[i], points[j], points[k]) == 0:
                    return None
    edges: list[tuple[int, int]] = []
    edge_start = 4 + 2 * n
    for edge_id in range(m):
        u, v = values[edge_start + 2 * edge_id:edge_start + 2 * edge_id + 2]
        if not (0 <= u < v < n):
            return None
        if edges and edges[-1] >= (u, v):
            return None
        edges.append((u, v))
    adjacency: list[list[int]] = [[] for _ in range(n)]
    for u, v in edges:
        adjacency[u].append(v)
        adjacency[v].append(u)
    # Connectedness is required; edge crossings are forbidden except at shared ends.
    reached = {source}
    frontier = [source]
    while frontier:
        u = frontier.pop()
        for v in adjacency[u]:
            if v not in reached:
                reached.add(v)
                frontier.append(v)
    if len(reached) != n:
        return None
    for i, (a, b) in enumerate(edges):
        for c, d in edges[i + 1:]:
            if len({a, b, c, d}) == 4:
                if (_orient(points[a], points[b], points[c]) *
                        _orient(points[a], points[b], points[d]) < 0 and
                        _orient(points[c], points[d], points[a]) *
                        _orient(points[c], points[d], points[b]) < 0):
                    return None
    target_point = points[target]
    start_distance = ((points[source][0] - target_point[0]) ** 2 +
                      (points[source][1] - target_point[1]) ** 2)
    if any((points[v][0] - target_point[0]) ** 2 +
           (points[v][1] - target_point[1]) ** 2 < start_distance
           for v in adjacency[source]):
        return None
    rotations: list[list[int]] = []
    for u in range(n):
        row = [(points[v][0] - points[u][0], points[v][1] - points[u][1], v)
               for v in adjacency[u]]
        for i in range(1, len(row)):
            item = row[i]
            j = i
            while j > 0 and _ccw_less(item, row[j - 1]):
                row[j] = row[j - 1]
                j -= 1
            row[j] = item
        rotations.append([item[2] for item in row])
    edge_ids = {edge: i for i, edge in enumerate(edges)}
    return n, m, source, target, points, edges, adjacency, rotations, edge_ids


def _first_ccw_from_ray(node: int, target: int, points: list[tuple[int, int]],
                        neighbors: list[int]) -> int:
    rx, ry = points[target][0] - points[node][0], points[target][1] - points[node][1]
    relative = []
    for v in neighbors:
        dx, dy = points[v][0] - points[node][0], points[v][1] - points[node][1]
        relative.append((rx * dx + ry * dy, _cross(rx, ry, dx, dy), v))
    for i in range(1, len(relative)):
        item = relative[i]
        j = i
        while j > 0 and _ccw_less(item, relative[j - 1]):
            relative[j] = relative[j - 1]
            j -= 1
        relative[j] = item
    return relative[0][2]


def _next_ccw(node: int, incoming: int, rotations: list[list[int]]) -> int:
    row = rotations[node]
    index = row.index(incoming)
    return row[(index + 1) % len(row)]


def _pack_record(status: int, path: list[int], crossings: list[tuple[int, int, int, int]]) -> bytes:
    words = [status, len(path) - 1, *path, len(crossings)]
    for event in crossings:
        words.extend(event)
    return b"".join(struct.pack("<q", value) for value in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or
            capacity is not None and (type(capacity) is not int or capacity < 0) or
            input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH) or
            input_is_null and values not in (None, [], ()) or
            not input_is_null and values is not None and input_length is not None and
            isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    n, m, source, target, points, edges, adjacency, rotations, edge_ids = decoded
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""

    path = [source]
    crossings: list[tuple[int, int, int, int]] = []
    current = source
    first_edge: tuple[int, int] | None = None
    previous: int | None = None
    lf = (0, 1)
    source_distance = ((points[source][0] - points[target][0]) ** 2 +
                       (points[source][1] - points[target][1]) ** 2)
    status = 0
    while True:
        distance = ((points[current][0] - points[target][0]) ** 2 +
                    (points[current][1] - points[target][1]) ** 2)
        if current == target:
            status = 2
            break
        if distance < source_distance:
            status = 1
            break
        if len(path) - 1 >= 2 * m:
            status = 0
            break
        if previous is None:
            candidate = _first_ccw_from_ray(current, target, points, adjacency[current])
        else:
            candidate = _next_ccw(current, previous, rotations)
        changed_face = False
        while True:
            edge = (min(current, candidate), max(current, candidate))
            t = _proper_intersection_parameter(points[source], points[target],
                                               points[current], points[candidate])
            if t is None or t[0] * lf[1] <= lf[0] * t[1]:
                break
            crossings.append((len(path) - 1, edge_ids[edge], t[0], t[1]))
            lf = t
            changed_face = True
            candidate = _next_ccw(current, candidate, rotations)
        directed = (current, candidate)
        if changed_face or first_edge is None:
            first_edge = directed
        elif directed == first_edge:
            status = 0
            break
        previous = current
        current = candidate
        path.append(current)
    else:
        status = 0
    output = _pack_record(status, path, crossings)
    return len(output), output
