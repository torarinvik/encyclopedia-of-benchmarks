"""Independent direct-prefix reference for a bounded Schnyder realizer."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 8 * MAX_N - 8
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 4 * (MAX_N - 3))


def _read(values: Sequence[int]):
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    n = values[0]
    if not 3 <= n <= MAX_N or len(values) < n + 4:
        return None
    frame, order = values[:-n], list(values[-n:])
    if len(frame) > 7 * MAX_N - 8 or len(frame) < 4:
        return None
    _, u, v, w = frame[:4]
    if len({u, v, w}) != 3 or any(not 0 <= root < n for root in (u, v, w)):
        return None
    around: list[list[int]] = []
    cursor = 4
    for vertex in range(n):
        if cursor >= len(frame):
            return None
        degree = frame[cursor]
        cursor += 1
        if not 2 <= degree < n or cursor + degree > len(frame):
            return None
        row = list(frame[cursor:cursor + degree])
        cursor += degree
        if (len(set(row)) != degree
                or any(not 0 <= x < n or x == vertex for x in row)):
            return None
        around.append(row)
    if cursor != len(frame) or sum(map(len, around)) != 6 * n - 12:
        return None

    edge = [[False] * n for _ in range(n)]
    for x, row in enumerate(around):
        for y in row:
            edge[x][y] = True
    if any(edge[x][y] != edge[y][x] for x in range(n) for y in range(n)):
        return None
    if sum(edge[x][y] for x in range(n) for y in range(x + 1, n)) != 3 * n - 6:
        return None

    reached = {u}
    frontier = [u]
    while frontier:
        x = frontier.pop()
        for y in range(n):
            if edge[x][y] and y not in reached:
                reached.add(y)
                frontier.append(y)
    if len(reached) != n:
        return None
    all_vertices = set(range(n))
    seen_darts: set[tuple[int, int]] = set()
    face_count = 0
    for x in range(n):
        for y in range(n):
            if not edge[x][y] or (x, y) in seen_darts:
                continue
            face = _face(around, edge, all_vertices, x, y)
            if face is None or len(face) != 3:
                return None
            face_count += 1
            for k in range(3):
                dart = (face[k], face[(k + 1) % 3])
                if dart in seen_darts:
                    return None
                seen_darts.add(dart)
    if (face_count != 2 * n - 4 or len(seen_darts) != 6 * n - 12
            or _face(around, edge, all_vertices, u, v) != [u, v, w]):
        return None
    return n, u, v, w, around, edge, order


def _face(around: list[list[int]], edge: list[list[bool]], active: set[int],
          first: int, second: int) -> list[int] | None:
    start = (first, second)
    dart = start
    walk: list[int] = []
    seen: set[tuple[int, int]] = set()
    for _ in range(2 * sum(map(sum, edge)) + 1):
        x, y = dart
        if x not in active or y not in active or not edge[x][y] or dart in seen:
            return walk if dart == start and len(walk) >= 3 else None
        seen.add(dart)
        walk.append(x)
        rotation = [z for z in around[y] if z in active]
        if len(rotation) < 2 or x not in rotation:
            return None
        z = rotation[(rotation.index(x) + 1) % len(rotation)]
        dart = (y, z)
        if dart == start:
            return walk
    return None


def _boundary(around: list[list[int]], edge: list[list[bool]], active: set[int],
              u: int, v: int) -> list[int] | None:
    face = _face(around, edge, active, u, v)
    if face is None:
        return None
    return [u, *reversed(face[2:]), v]


def _connected(vertices: set[int], edge: list[list[bool]], omit: int | None = None) -> bool:
    remain = vertices - ({omit} if omit is not None else set())
    if len(remain) < 2:
        return True
    root = min(remain)
    seen = {root}
    todo = [root]
    while todo:
        x = todo.pop()
        for y in remain:
            if edge[x][y] and y not in seen:
                seen.add(y)
                todo.append(y)
    return seen == remain


def _prefix_order_ok(n: int, u: int, v: int, w: int, around: list[list[int]],
                     edge: list[list[bool]], order: list[int]) -> bool:
    if (len(order) != n or set(order) != set(range(n))
            or order[:2] != [u, v] or order[-1] != w):
        return False
    all_vertices = set(range(n))
    outer = _face(around, edge, all_vertices, u, v)
    if outer != [u, v, w]:
        return False
    prefix = {u, v}
    if n == 3:
        return prefix == all_vertices - {w}
    for rank in range(2, n):
        vertex = order[rank]
        if vertex in prefix:
            return False
        if rank == 2:
            if not edge[vertex][u] or not edge[vertex][v]:
                return False
            prefix.add(vertex)
            if (_boundary(around, edge, prefix, u, v) != [u, vertex, v]
                    or not _connected(prefix, edge)
                    or any(not _connected(prefix, edge, x) for x in prefix)):
                return False
        else:
            path = _boundary(around, edge, prefix, u, v)
            if path is None:
                return False
            earlier = {x for x in prefix if edge[vertex][x]}
            boundary_neighbors = [x for x in path if edge[vertex][x]]
            if len(boundary_neighbors) < 2 or earlier != set(boundary_neighbors):
                return False
            positions = [path.index(x) for x in boundary_neighbors]
            if max(positions) - min(positions) + 1 != len(positions):
                return False
            prefix.add(vertex)
            if not _connected(prefix, edge) or any(not _connected(prefix, edge, x) for x in prefix):
                return False
    return prefix == all_vertices


def _result(parsed):
    n, u, v, w, around, edge, order = parsed
    if not _prefix_order_ok(n, u, v, w, around, edge, order):
        return None
    rank = [0] * n
    for i, vertex in enumerate(order):
        rank[vertex] = i
    records: list[tuple[int, int, int, int]] = []
    for i in range(2, n - 1):
        vertex = order[i]
        if i == 2:
            left, right = u, v
        else:
            path = _boundary(around, edge, set(order[:i]), u, v)
            if path is None:
                return None
            earlier = [x for x in path if edge[vertex][x]]
            if len(earlier) < 2:
                return None
            left, right = earlier[0], earlier[-1]
        successors = [x for x in range(n) if edge[vertex][x] and rank[x] > i]
        if not successors:
            return None
        later = max(successors, key=rank.__getitem__)
        records.append((vertex, left, right, later))
    if not _check_trees(n, u, v, w, around, edge, records):
        return None
    return n, records


def _check_trees(n: int, u: int, v: int, w: int, around: list[list[int]],
                 edge: list[list[bool]],
                 records: list[tuple[int, int, int, int]]) -> bool:
    if len(records) != n - 3:
        return False
    roots = (u, v, w)
    parent = [{row[0]: row[color + 1] for row in records} for color in range(3)]
    selected: set[tuple[int, int]] = set()
    colors = [[-1] * n for _ in range(n)]
    owners = [[-1] * n for _ in range(n)]
    for row in records:
        vertex, *targets = row
        if len(set(targets)) != 3:
            return False
        for color, target in enumerate(targets):
            if not 0 <= target < n or not edge[vertex][target]:
                return False
            e = tuple(sorted((vertex, target)))
            if e in selected:
                return False
            selected.add(e)
            colors[vertex][target] = colors[target][vertex] = color
            owners[vertex][target] = owners[target][vertex] = vertex
            trail: set[int] = set()
            current = vertex
            while current != roots[color]:
                if current in trail or current not in parent[color]:
                    return False
                trail.add(current)
                current = parent[color][current]
    outer_edges = {tuple(sorted(pair)) for pair in ((u, v), (v, w), (w, u))}
    all_internal = {tuple((x, y)) for x in range(n) for y in range(x + 1, n)
                    if edge[x][y] and (x, y) not in outer_edges}
    if selected != all_internal:
        return False

    # Clockwise around an interior vertex: out T1, in T2, out T3, in T1,
    # out T2, in T3. Any incoming sector may be empty.
    for vertex in range(n):
        if vertex in roots:
            continue
        outgoing_position = [-1] * 3
        tokens: list[int] = []
        # The rotation row is stored in the face-walk successor orientation;
        # with u,v,w counterclockwise on the outer face, the chapter's local
        # clockwise view is its reverse cyclic traversal.
        for position, neighbor in enumerate(reversed(around[vertex])):
            color = colors[vertex][neighbor]
            if color < 0:
                return False
            if owners[vertex][neighbor] == vertex:
                if outgoing_position[color] >= 0:
                    return False
                outgoing_position[color] = position
                tokens.append(color)
            else:
                tokens.append(3 + color)
        if any(position < 0 for position in outgoing_position):
            return False
        degree = len(tokens)
        phases = ((0, 2, 4), (2, 1, 3), (1, 0, 5))
        for start_color, next_color, incoming_token in phases:
            position = outgoing_position[start_color]
            next_position = outgoing_position[next_color]
            position = (position + 1) % degree
            while position != next_position:
                if tokens[position] != incoming_token:
                    return False
                position = (position + 1) % degree
    return True


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    parsed = _read(values)
    result = None if parsed is None else _result(parsed)
    if result is None:
        return -1, b""
    n, records = result
    words = (n, *(word for row in records for word in row))
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
