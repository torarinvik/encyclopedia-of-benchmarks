"""Independent path-enumeration and dual-cut reference for a cyclic wedge."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from itertools import combinations

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 54
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 128


def _same_cycle(a: list[int], b: list[int]) -> bool:
    return len(a) == len(b) and any(a == b[i:] + b[:i] for i in range(len(b)))


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, k, b = values[:3]
    if (not 4 <= n <= MAX_N or not 3 <= k <= MAX_N or (n - 1) % k
            or not k <= b <= n or b % k):
        return None
    pos = 3
    if pos + b > len(values):
        return None
    outer = list(values[pos:pos + b])
    pos += b
    if len(set(outer)) != b or any(v < 0 or v >= n for v in outer):
        return None
    rows: list[list[int]] = []
    adj = [[False] * n for _ in range(n)]
    degree_sum = 0
    for v in range(n):
        if pos == len(values):
            return None
        degree = values[pos]
        pos += 1
        if not 3 <= degree < n or pos + degree > len(values):
            return None
        row = list(values[pos:pos + degree])
        pos += degree
        if len(set(row)) != degree or any(w < 0 or w >= n or w == v for w in row):
            return None
        rows.append(row)
        degree_sum += degree
        for w in row:
            adj[v][w] = True
    if pos + n != len(values) or degree_sum % 2:
        return None
    perm = list(values[pos:pos + n])
    if len(set(perm)) != n or any(v < 0 or v >= n for v in perm):
        return None
    m = degree_sum // 2
    if not n <= m <= 3 * n - 6 or any(adj[u][v] != adj[v][u]
                                        for u in range(n) for v in range(n)):
        return None
    edges = [(u, v) for u in range(n) for v in range(u + 1, n) if adj[u][v]]

    # Direct connectivity after deleting up to two vertices pins 3-connectivity.
    for removed_size in (0, 1, 2):
        for removed_tuple in combinations(range(n), removed_size):
            keep = set(range(n)) - set(removed_tuple)
            root = min(keep)
            reached = {root}
            stack = [root]
            while stack:
                u = stack.pop()
                for v in keep:
                    if adj[u][v] and v not in reached:
                        reached.add(v)
                        stack.append(v)
            if reached != keep:
                return None

    def successor_dart(u: int, v: int) -> tuple[int, int]:
        row = rows[v]
        return v, row[(row.index(u) + 1) % len(row)]

    face_of: dict[tuple[int, int], int] = {}
    faces: list[list[int]] = []
    for a, b_edge in edges:
        for start in ((a, b_edge), (b_edge, a)):
            if start in face_of:
                continue
            cycle: list[int] = []
            dart = start
            for _ in range(2 * m + 1):
                if dart in face_of:
                    return None
                face_of[dart] = -1
                cycle.append(dart[0])
                dart = successor_dart(*dart)
                if dart == start:
                    break
            else:
                return None
            if len(cycle) < 3 or len(set(cycle)) != len(cycle):
                return None
            face_id = len(faces)
            for i, u in enumerate(cycle):
                face_of[u, cycle[(i + 1) % len(cycle)]] = face_id
            faces.append(cycle)
    if len(faces) != m - n + 2 or len(face_of) != 2 * m:
        return None
    outer_id = next((i for i, face in enumerate(faces) if _same_cycle(face, outer)), -1)
    if outer_id < 0:
        return None

    fixed = [u for u in range(n) if perm[u] == u]
    if len(fixed) != 1 or fixed[0] in outer:
        return None
    center = fixed[0]
    for vertex in range(n):
        if vertex == center:
            continue
        current = perm[vertex]
        orbit_length = 1
        while current != vertex and orbit_length <= k:
            current = perm[current]
            orbit_length += 1
        if current != vertex or orbit_length != k:
            return None
    power = list(range(n))
    for step in range(1, k + 1):
        power = [perm[x] for x in power]
        if (power == list(range(n))) != (step == k):
            return None
    for u in range(n):
        if any(adj[u][v] != adj[perm[u]][perm[v]] for v in range(n)):
            return None
        image_row = [perm[v] for v in rows[u]]
        if not any(image_row == rows[perm[u]][r:] + rows[perm[u]][:r]
                   for r in range(len(image_row))):
            return None
    valid_shifts = [d for d in range(1, b)
                    if all(perm[outer[i]] == outer[(i + d) % b] for i in range(b))]
    if valid_shifts != [b // k]:
        return None
    return n, k, b, outer, rows, adj, perm, center, edges, faces, face_of, outer_id


def _result(parsed):
    n, k, b, outer, rows, adj, perm, center, edges, faces, face_of, outer_id = parsed
    candidates: list[list[int]] = []

    def visit(path: list[int], used: set[int]) -> None:
        last = path[-1]
        if last in outer:
            candidates.append(path.copy())
            return
        for next_vertex in range(n):
            if adj[last][next_vertex] and next_vertex not in used:
                used.add(next_vertex)
                path.append(next_vertex)
                visit(path, used)
                path.pop()
                used.remove(next_vertex)

    visit([center], {center})
    if not candidates:
        return None
    p1 = min(candidates, key=lambda path: (len(path), path[-1], tuple(path)))
    endpoint = p1[-1]
    p2 = [perm[v] for v in p1]
    endpoint2 = p2[-1]
    if (len(set(p1) & set(p2)) != 1 or center not in p1 or center not in p2
            or any(v in outer for v in p1[1:-1] + p2[1:-1])):
        return None
    start = outer.index(endpoint)
    p0 = [outer[(start + step) % b] for step in range(b // k + 1)]
    if p0[-1] != endpoint2:
        return None
    cycle = p1 + p0[1:] + list(reversed(p2[:-1]))
    if cycle[-1] != center or len(set(cycle[:-1])) != len(cycle) - 1:
        return None
    cycle_edges = {tuple(sorted((cycle[i], cycle[i + 1]))) for i in range(len(cycle) - 1)}
    if len(cycle_edges) != len(cycle) - 1:
        return None

    # Search all face subsets, selecting the side whose dual cut is the cycle.
    # This differs from the primary reference's flood fill across uncut dual edges.
    candidates_of_faces: list[set[int]] = []
    for mask in range(1, 1 << len(faces)):
        if mask & (1 << outer_id):
            continue
        selected = {f for f in range(len(faces)) if (mask >> f) & 1}
        boundary = set()
        for u, v in edges:
            left, right = face_of[u, v], face_of[v, u]
            if (left in selected) != (right in selected):
                boundary.add((u, v))
        if boundary == cycle_edges:
            candidates_of_faces.append(selected)
    if len(candidates_of_faces) != 1:
        return None
    wedge_faces = candidates_of_faces[0]
    wedge_vertices = set(cycle[:-1])
    for face_id in wedge_faces:
        wedge_vertices.update(faces[face_id])
    vertex_mask = sum(1 << v for v in wedge_vertices)
    edge_mask = sum(1 << i for i, (u, v) in enumerate(edges)
                    if u in wedge_vertices and v in wedge_vertices)
    words = [len(p1), *p1, len(p2), *p2, len(p0), *p0, vertex_mask, edge_mask]
    return b"".join(struct.pack("<q", value) for value in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    payload = _result(parsed)
    if payload is None or len(payload) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
