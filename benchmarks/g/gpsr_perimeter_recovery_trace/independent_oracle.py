"""Independent on-demand-rotation GPSR replay and exact geometry reference."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction
from functools import cmp_to_key

MAX_N = 8
MAX_M = 18
MAX_VALID_INPUT_LENGTH = 56
MAX_PARSEABLE_INPUT_LENGTH = 57
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_INPUT = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 896
WORKSPACE_BYTES = 8192


def _det(a: tuple[int, int], b: tuple[int, int]) -> int:
    return a[0] * b[1] - a[1] * b[0]


def _area(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return _det((b[0] - a[0], b[1] - a[1]), (c[0] - a[0], c[1] - a[1]))


def _polar_compare(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    ah = 0 if a[1] > 0 or (a[1] == 0 and a[0] >= 0) else 1
    bh = 0 if b[1] > 0 or (b[1] == 0 and b[0] >= 0) else 1
    if ah != bh:
        return -1 if ah < bh else 1
    turn = _det(a[:2], b[:2])
    if turn:
        return -1 if turn > 0 else 1
    return (a[2] > b[2]) - (a[2] < b[2])


def _cross_parameter(p: tuple[int, int], q: tuple[int, int],
                     a: tuple[int, int], b: tuple[int, int]) -> Fraction | None:
    r = (q[0] - p[0], q[1] - p[1])
    s = (b[0] - a[0], b[1] - a[1])
    divisor = _det(r, s)
    if divisor == 0:
        return None
    offset = (a[0] - p[0], a[1] - p[1])
    t_num = _det(offset, s)
    u_num = _det(offset, r)
    if divisor < 0:
        divisor, t_num, u_num = -divisor, -t_num, -u_num
    if 0 < t_num < divisor and 0 < u_num < divisor:
        return Fraction(t_num, divisor)
    return None


def _decode(frame: Sequence[int] | None):
    if (not isinstance(frame, (list, tuple)) or
            len(frame) < 4 or len(frame) > MAX_PARSEABLE_INPUT_LENGTH or
            any(type(w) is not int or not -(1 << 63) <= w < (1 << 63) for w in frame)):
        return None
    n, m, start, goal = frame[:4]
    if n < 3 or n > MAX_N or m < n - 1 or m > min(MAX_M, 3*n - 6):
        return None
    if start < 0 or goal < 0 or start >= n or goal >= n or start == goal:
        return None
    if len(frame) != 4 + 2*n + 2*m:
        return None
    coords = list(zip(frame[4:4+n], frame[4+n:4+2*n]))
    if any(not -16 <= z <= 16 for point in coords for z in point):
        return None
    if len(set(coords)) != n:
        return None
    # Reject all collinear triples so the line walk has no vertex/tie events.
    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                if _area(coords[a], coords[b], coords[c]) == 0:
                    return None
    edges = []
    offset = 4 + 2*n
    for i in range(m):
        u, v = frame[offset + 2*i:offset + 2*i + 2]
        if u < 0 or v >= n or u >= v:
            return None
        pair = (u, v)
        if edges and pair <= edges[-1]:
            return None
        edges.append(pair)
    adj = [[] for _ in range(n)]
    for u, v in edges:
        adj[u].append(v)
        adj[v].append(u)
    pending, reached = [start], {start}
    while pending:
        x = pending.pop()
        for y in adj[x]:
            if y not in reached:
                reached.add(y)
                pending.append(y)
    if len(reached) != n:
        return None
    for i, (u, v) in enumerate(edges):
        for a, b in edges[i+1:]:
            if len({u, v, a, b}) == 4:
                if (_area(coords[u], coords[v], coords[a]) * _area(coords[u], coords[v], coords[b]) < 0
                        and _area(coords[a], coords[b], coords[u]) * _area(coords[a], coords[b], coords[v]) < 0):
                    return None
    gdist = lambda x: (coords[x][0] - coords[goal][0])**2 + (coords[x][1] - coords[goal][1])**2
    if any(gdist(v) < gdist(start) for v in adj[start]):
        return None
    return n, m, start, goal, coords, edges, adj


def _next_on_rotation(node: int, incoming: int, coords: list[tuple[int, int]],
                      adj: list[list[int]]) -> int:
    angles = [(coords[v][0] - coords[node][0], coords[v][1] - coords[node][1], v)
              for v in adj[node]]
    angles.sort(key=cmp_to_key(_polar_compare))
    for i, item in enumerate(angles):
        if item[2] == incoming:
            return angles[(i + 1) % len(angles)][2]
    raise ValueError("incoming neighbor not incident")


def _initial_edge(node: int, goal: int, coords: list[tuple[int, int]],
                  adj: list[list[int]]) -> int:
    ray = (coords[goal][0] - coords[node][0], coords[goal][1] - coords[node][1])
    relative = []
    for v in adj[node]:
        vector = (coords[v][0] - coords[node][0], coords[v][1] - coords[node][1])
        relative.append((ray[0]*vector[0] + ray[1]*vector[1], _det(ray, vector), v))
    relative.sort(key=cmp_to_key(_polar_compare))
    return relative[0][2]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or
            capacity is not None and (type(capacity) is not int or capacity < 0) or
            input_length is not None and (type(input_length) is not int or
                                          not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH) or
            input_is_null and values not in (None, [], ()) or
            not input_is_null and values is not None and input_length is not None and
            isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    n, m, start, goal, coords, edges, adj = parsed
    if output_is_null or (capacity is not None and capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    edge_number = {edge: i for i, edge in enumerate(edges)}
    edge_number.update({(v, u): i for i, (u, v) in enumerate(edges)})
    base_distance = (coords[start][0] - coords[goal][0])**2 + (coords[start][1] - coords[goal][1])**2
    last_crossing = Fraction(0, 1)
    trace: list[tuple[int, int, int, int]] = []
    route = [start]
    node, came_from = start, None
    first_directed = None
    status = 0
    while True:
        distance = (coords[node][0] - coords[goal][0])**2 + (coords[node][1] - coords[goal][1])**2
        if node == goal:
            status = 2
            break
        if distance < base_distance:
            status = 1
            break
        if len(route) - 1 >= 2*m:
            status = 0
            break
        candidate = (_initial_edge(node, goal, coords, adj) if came_from is None else
                     _next_on_rotation(node, came_from, coords, adj))
        face_changed = False
        while True:
            p = _cross_parameter(coords[start], coords[goal], coords[node], coords[candidate])
            if p is None or p <= last_crossing:
                break
            edge_id = edge_number[(node, candidate)]
            trace.append((len(route)-1, edge_id, p.numerator, p.denominator))
            last_crossing = p
            face_changed = True
            candidate = _next_on_rotation(node, candidate, coords, adj)
        dart = (node, candidate)
        if face_changed or first_directed is None:
            first_directed = dart
        elif dart == first_directed:
            status = 0
            break
        came_from, node = node, candidate
        route.append(node)
    words = [status, len(route)-1, *route, len(trace)]
    for event in trace:
        words.extend(event)
    data = b"".join(struct.pack("<q", word) for word in words)
    return len(data), data
