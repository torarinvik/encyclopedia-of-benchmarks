"""Primary bounded reference for cyclic-symmetry wedge extraction."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 54
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 128
WORKSPACE_BYTES = 16384


def _cyclic_equal(left: list[int], right: list[int]) -> bool:
    if len(left) != len(right):
        return False
    if not left:
        return True
    return any(left == right[offset:] + right[:offset] for offset in range(len(right)))


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, order, boundary_length = values[:3]
    if (not 4 <= n <= MAX_N or not 3 <= order <= MAX_N or (n - 1) % order != 0
            or not order <= boundary_length <= n or boundary_length % order != 0):
        return None
    offset = 3
    if offset + boundary_length > len(values):
        return None
    outer = list(values[offset:offset + boundary_length])
    offset += boundary_length
    if (len(set(outer)) != boundary_length
            or any(not 0 <= vertex < n for vertex in outer)):
        return None

    rotation: list[list[int]] = []
    adjacency = [[False] * n for _ in range(n)]
    degree_sum = 0
    for vertex in range(n):
        if offset >= len(values):
            return None
        degree = values[offset]
        offset += 1
        if not 3 <= degree < n or offset + degree > len(values):
            return None
        row = list(values[offset:offset + degree])
        offset += degree
        if (len(set(row)) != degree
                or any(not 0 <= neighbor < n or neighbor == vertex for neighbor in row)):
            return None
        rotation.append(row)
        degree_sum += degree
        for neighbor in row:
            adjacency[vertex][neighbor] = True
    if offset + n != len(values):
        return None
    permutation = list(values[offset:offset + n])
    if len(set(permutation)) != n or any(not 0 <= vertex < n for vertex in permutation):
        return None
    if degree_sum % 2:
        return None
    m = degree_sum // 2
    if not n <= m <= 3 * n - 6:
        return None
    if any(adjacency[u][v] != adjacency[v][u]
           for u in range(n) for v in range(n)):
        return None
    edges = [(u, v) for u in range(n) for v in range(u + 1, n) if adjacency[u][v]]

    # The supplied rotations must describe a simple sphere embedding.
    reached = {0}
    todo = [0]
    while todo:
        u = todo.pop()
        for v in range(n):
            if adjacency[u][v] and v not in reached:
                reached.add(v)
                todo.append(v)
    if len(reached) != n:
        return None
    for removed_count in range(3):
        from itertools import combinations
        for removed in combinations(range(n), removed_count):
            remaining = set(range(n)) - set(removed)
            if len(remaining) < 2:
                continue
            start = min(remaining)
            seen = {start}
            todo = [start]
            while todo:
                u = todo.pop()
                for v in remaining:
                    if adjacency[u][v] and v not in seen:
                        seen.add(v)
                        todo.append(v)
            if seen != remaining:
                return None

    def walk_face(first: int, second: int) -> list[int] | None:
        start = (first, second)
        dart = start
        cycle: list[int] = []
        seen_darts: set[tuple[int, int]] = set()
        for _ in range(2 * m + 1):
            u, v = dart
            if not adjacency[u][v] or dart in seen_darts:
                return None
            seen_darts.add(dart)
            cycle.append(u)
            around = rotation[v]
            following = around[(around.index(u) + 1) % len(around)]
            dart = (v, following)
            if dart == start:
                return cycle
        return None

    faces: list[list[int]] = []
    dart_face: dict[tuple[int, int], int] = {}
    for u, v in edges:
        for first, second in ((u, v), (v, u)):
            if (first, second) in dart_face:
                continue
            face = walk_face(first, second)
            if face is None or len(face) < 3 or len(set(face)) != len(face):
                return None
            face_id = len(faces)
            faces.append(face)
            for index, source in enumerate(face):
                target = face[(index + 1) % len(face)]
                if (source, target) in dart_face:
                    return None
                dart_face[source, target] = face_id
    if len(faces) != m - n + 2 or len(dart_face) != 2 * m:
        return None

    outer_id = -1
    for face_id, face in enumerate(faces):
        if _cyclic_equal(face, outer):
            outer_id = face_id
            break
    if outer_id < 0:
        return None

    fixed = [vertex for vertex in range(n) if permutation[vertex] == vertex]
    if len(fixed) != 1 or fixed[0] in outer:
        return None
    center = fixed[0]
    for vertex in range(n):
        if vertex == center:
            continue
        current = permutation[vertex]
        orbit_length = 1
        while current != vertex and orbit_length <= order:
            current = permutation[current]
            orbit_length += 1
        if current != vertex or orbit_length != order:
            return None
    power = list(range(n))
    for exponent in range(1, order + 1):
        power = [permutation[power[vertex]] for vertex in range(n)]
        is_identity = power == list(range(n))
        if is_identity != (exponent == order):
            return None
    for u in range(n):
        for v in range(n):
            if adjacency[u][v] != adjacency[permutation[u]][permutation[v]]:
                return None
        mapped_row = [permutation[v] for v in rotation[u]]
        if not _cyclic_equal(mapped_row, rotation[permutation[u]]):
            return None
    shifts = [step for step in range(1, boundary_length)
              if all(permutation[outer[i]] == outer[(i + step) % boundary_length]
                     for i in range(boundary_length))]
    if shifts != [boundary_length // order]:
        return None
    return (n, order, boundary_length, outer, rotation, adjacency, permutation,
            center, edges, faces, dart_face, outer_id)


def _solve(parsed):
    (n, order, boundary_length, outer, rotation, adjacency, permutation,
     center, edges, faces, dart_face, outer_id) = parsed
    distance = [-1] * n
    distance[center] = 0
    queue = deque([center])
    while queue:
        u = queue.popleft()
        for v in sorted(rotation[u]):
            if distance[v] < 0:
                distance[v] = distance[u] + 1
                queue.append(v)
    endpoint = min(outer, key=lambda vertex: (distance[vertex], vertex))
    if distance[endpoint] <= 0:
        return None

    to_endpoint = [-1] * n
    to_endpoint[endpoint] = 0
    queue = deque([endpoint])
    while queue:
        u = queue.popleft()
        for v in sorted(rotation[u]):
            if to_endpoint[v] < 0:
                to_endpoint[v] = to_endpoint[u] + 1
                queue.append(v)
    p1 = [center]
    current = center
    while current != endpoint:
        options = [v for v in rotation[current]
                   if to_endpoint[v] == to_endpoint[current] - 1]
        if not options:
            return None
        current = min(options)
        p1.append(current)
    if len(p1) - 1 != distance[endpoint]:
        return None
    p2 = [permutation[v] for v in p1]
    endpoint2 = p2[-1]
    if endpoint2 not in outer or endpoint2 == endpoint:
        return None
    if set(p1) & set(p2) != {center}:
        return None
    if any(vertex in outer for vertex in p1[1:-1] + p2[1:-1]):
        return None

    start = outer.index(endpoint)
    p0 = [outer[(start + step) % boundary_length]
          for step in range(boundary_length // order + 1)]
    if p0[0] != endpoint or p0[-1] != endpoint2:
        return None
    cycle = p1 + p0[1:] + list(reversed(p2[:-1]))
    if len(cycle) < 4 or cycle[-1] != center or len(set(cycle[:-1])) != len(cycle) - 1:
        return None
    cycle_edges = {tuple(sorted((cycle[i], cycle[i + 1])))
                   for i in range(len(cycle) - 1)}
    if len(cycle_edges) != len(cycle) - 1 or any(not adjacency[u][v] for u, v in cycle_edges):
        return None

    seed_face = dart_face.get((p0[1], p0[0]))
    if seed_face is None or seed_face == outer_id:
        return None
    dual = [[] for _ in faces]
    for u, v in edges:
        if (u, v) in cycle_edges:
            continue
        left = dart_face[u, v]
        right = dart_face[v, u]
        dual[left].append(right)
        dual[right].append(left)
    wedge_faces = {seed_face}
    stack = [seed_face]
    while stack:
        face_id = stack.pop()
        for other in dual[face_id]:
            if other not in wedge_faces:
                wedge_faces.add(other)
                stack.append(other)
    if outer_id in wedge_faces:
        return None
    wedge_vertices = set(cycle[:-1])
    for face_id in wedge_faces:
        wedge_vertices.update(faces[face_id])
    vertex_mask = sum(1 << vertex for vertex in wedge_vertices)
    edge_mask = sum(1 << index for index, (u, v) in enumerate(edges)
                    if u in wedge_vertices and v in wedge_vertices)
    words = [len(p1), *p1, len(p2), *p2, len(p0), *p0, vertex_mask, edge_mask]
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    payload = _solve(parsed)
    if payload is None or len(payload) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
