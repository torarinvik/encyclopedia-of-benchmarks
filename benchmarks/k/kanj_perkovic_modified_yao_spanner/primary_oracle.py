"""Bounded modified-Yao edge-selection pass from Kanj--Perkovic."""

from __future__ import annotations

MAX_VERTICES = 16
MAX_EDGES = 42
MAX_CONES = 14
MAX_VALID_INPUT_LENGTH = 2 + MAX_VERTICES + 7 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 16384


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    n, m = values[0], values[1]
    if not 3 <= n <= MAX_VERTICES or not n - 1 <= m <= min(MAX_EDGES, 3 * n - 6):
        return None
    expected = 2 + 5 * m + n + 2 * m
    if len(values) != expected:
        return None

    edges = []
    outgoing = [[] for _ in range(n)]
    last_pair = None
    offset = 2
    for edge_id in range(m):
        u, v, weight2, cone_u, cone_v = values[offset:offset + 5]
        offset += 5
        pair = (u, v)
        if (not 0 <= u < v < n or not 1 <= weight2 <= 10**12
                or not 0 <= cone_u < MAX_CONES or not 0 <= cone_v < MAX_CONES
                or (last_pair is not None and pair <= last_pair)):
            return None
        last_pair = pair
        edges.append((u, v, weight2, cone_u, cone_v))
        outgoing[u].append(2 * edge_id)
        outgoing[v].append(2 * edge_id + 1)

    rotations = []
    dart_seen = [False] * (2 * m)
    for vertex in range(n):
        degree = values[offset]
        offset += 1
        if degree != len(outgoing[vertex]) or not 1 <= degree <= MAX_EDGES:
            return None
        row = list(values[offset:offset + degree])
        offset += degree
        if len(row) != degree:
            return None
        previous_cone = -1
        for dart in row:
            if not 0 <= dart < 2 * m or dart_seen[dart]:
                return None
            edge = edges[dart // 2]
            source = edge[0] if dart % 2 == 0 else edge[1]
            cone = edge[3] if dart % 2 == 0 else edge[4]
            if source != vertex or cone < previous_cone:
                return None
            previous_cone = cone
            dart_seen[dart] = True
        rotations.append(row)
    if offset != len(values) or not all(dart_seen):
        return None

    # Connectedness plus Euler's formula checks that the supplied rotation
    # system is a genus-zero embedding. Geometry/cone realization is a caller
    # precondition and is outside this selection-pass benchmark.
    adjacency = [[] for _ in range(n)]
    for edge_id, (u, v, *_rest) in enumerate(edges):
        adjacency[u].append(v)
        adjacency[v].append(u)
    reached = {0}
    stack = [0]
    while stack:
        u = stack.pop()
        for v in adjacency[u]:
            if v not in reached:
                reached.add(v)
                stack.append(v)
    if len(reached) != n:
        return None

    position = [-1] * (2 * m)
    for vertex, row in enumerate(rotations):
        for index, dart in enumerate(row):
            position[dart] = index
    face_next = [0] * (2 * m)
    for dart in range(2 * m):
        twin = dart ^ 1
        edge = edges[dart // 2]
        destination = edge[1] if dart % 2 == 0 else edge[0]
        row = rotations[destination]
        face_next[dart] = row[(position[twin] - 1) % len(row)]
    face_seen = [False] * (2 * m)
    faces = 0
    for dart in range(2 * m):
        if face_seen[dart]:
            continue
        faces += 1
        current = dart
        while not face_seen[current]:
            face_seen[current] = True
            current = face_next[current]
        if current != dart:
            return None
    if n - m + faces != 2:
        return None
    return n, m, edges, rotations


def _trace(decoded):
    n, m, edges, rotations = decoded
    selected = [False] * (2 * m)
    cones = [[[] for _ in range(MAX_CONES)] for _ in range(n)]
    for vertex, row in enumerate(rotations):
        for dart in row:
            edge = edges[dart // 2]
            cone = edge[3] if dart % 2 == 0 else edge[4]
            cones[vertex][cone].append(dart)

    # Ordinary Yao choices: shortest edge in each occupied cone.
    for vertex in range(n):
        for row in cones[vertex]:
            if row:
                winner = min(row, key=lambda d: (edges[d // 2][2], d // 2))
                selected[winner] = True

    # The paper's modified rule fills the sides of cyclic empty-cone runs.
    for vertex in range(n):
        occupied = [bool(row) for row in cones[vertex]]
        if not any(occupied):
            continue
        for start in range(MAX_CONES):
            if occupied[start] or not occupied[(start - 1) % MAX_CONES]:
                continue
            length = 0
            while length < MAX_CONES and not occupied[(start + length) % MAX_CONES]:
                length += 1
            if length == 1:
                clockwise = cones[vertex][(start - 1) % MAX_CONES][-1]
                counterclockwise = cones[vertex][(start + 1) % MAX_CONES][0]
                if selected[clockwise]:
                    selected[counterclockwise] = True
                elif selected[counterclockwise]:
                    selected[clockwise] = True
                else:
                    selected[min((clockwise, counterclockwise), key=lambda d: (edges[d // 2][2], d // 2))] = True
            else:
                need_cw, need_ccw = length // 2, (length + 1) // 2
                for step in range(1, MAX_CONES + 1):
                    if need_cw == 0:
                        break
                    cone = (start - step) % MAX_CONES
                    for dart in reversed(cones[vertex][cone]):
                        if not selected[dart]:
                            selected[dart] = True
                            need_cw -= 1
                            if need_cw == 0:
                                break
                for step in range(length, length + MAX_CONES):
                    if need_ccw == 0:
                        break
                    cone = (start + step) % MAX_CONES
                    for dart in cones[vertex][cone]:
                        if not selected[dart]:
                            selected[dart] = True
                            need_ccw -= 1
                            if need_ccw == 0:
                                break

    mask = 0
    for edge_id in range(m):
        if selected[2 * edge_id] and selected[2 * edge_id + 1]:
            mask |= 1 << edge_id
    return mask


def expected_result(values, input_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    return _trace(decoded)
