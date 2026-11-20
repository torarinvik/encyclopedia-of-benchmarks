"""Reverse-dual-potential and leftmost-augmentation reference; never run here."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 6
MAX_M = 10
MAX_VALID_INPUT_LENGTH = 60
MAX_PARSEABLE_INPUT_LENGTH = 61
MAX_OUTPUT_BYTES = 8
MAX_WORKSPACE_BYTES = 8192
WORKSPACE_BYTES = MAX_WORKSPACE_BYTES
SYMBOL = "planar_directed_general_st_flow_borradaile_klein"


def _decode(values: Sequence[int]):
    if not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    n, m, source, sink = values[:4]
    if not 2 <= n <= MAX_N or not 1 <= m <= MAX_M:
        return None
    if not 0 <= source < n or not 0 <= sink < n or source == sink:
        return None
    if len(values) < 4 + 3 * m:
        return None

    edges: list[tuple[int, int, int]] = []
    pairs: set[tuple[int, int]] = set()
    at = 4
    for _ in range(m):
        u, v, capacity = values[at : at + 3]
        at += 3
        pair = (min(u, v), max(u, v))
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        if not 1 <= capacity <= 5 or pair in pairs:
            return None
        pairs.add(pair)
        edges.append((u, v, capacity))

    rotations: list[list[int]] = []
    occurrence = [[0, 0] for _ in range(m)]
    for vertex in range(n):
        if at >= len(values):
            return None
        degree = values[at]
        at += 1
        if not 0 <= degree <= n - 1 or at + degree > len(values):
            return None
        row = list(values[at : at + degree])
        at += degree
        if len(set(row)) != degree:
            return None
        for edge_id in row:
            if not 0 <= edge_id < m:
                return None
            u, v, _ = edges[edge_id]
            if vertex == u:
                occurrence[edge_id][0] += 1
            elif vertex == v:
                occurrence[edge_id][1] += 1
            else:
                return None
        rotations.append(row)
    if at != len(values) or any(pair != [1, 1] for pair in occurrence):
        return None

    # Connectedness is required for the rotation-system Euler test below.
    adjacent = [[] for _ in range(n)]
    for edge_id, (u, v, _) in enumerate(edges):
        adjacent[u].append((v, edge_id))
        adjacent[v].append((u, edge_id))
    reached = {source}
    stack = [source]
    while stack:
        u = stack.pop()
        for v, _ in adjacent[u]:
            if v not in reached:
                reached.add(v)
                stack.append(v)
    if len(reached) != n:
        return None

    # A dart 2e points with the supplied arc; 2e+1 is its reverse.
    local_index = [[-1] * m for _ in range(n)]
    for vertex, row in enumerate(rotations):
        for position, edge_id in enumerate(row):
            local_index[vertex][edge_id] = position

    def tail(dart: int) -> int:
        u, v, _ = edges[dart // 2]
        return u if dart % 2 == 0 else v

    def head(dart: int) -> int:
        u, v, _ = edges[dart // 2]
        return v if dart % 2 == 0 else u

    def left_successor(dart: int) -> int:
        vertex = head(dart)
        edge_id = dart // 2
        row = rotations[vertex]
        reverse_position = local_index[vertex][edge_id]
        if reverse_position < 0 or not row:
            return -1
        previous_edge = row[(reverse_position - 1) % len(row)]
        u, v, _ = edges[previous_edge]
        return 2 * previous_edge + (1 if vertex == v else 0)

    left_face = [-1] * (2 * m)
    face_count = 0
    for start in range(2 * m):
        if left_face[start] >= 0:
            continue
        dart = start
        while left_face[dart] < 0:
            left_face[dart] = face_count
            dart = left_successor(dart)
            if dart < 0:
                return None
        if dart != start:
            return None
        face_count += 1
    if face_count != m - n + 2:
        return None

    right_face = [left_face[dart ^ 1] for dart in range(2 * m)]
    # Infinity is the face right of the local dart starting at t along its
    # first listed incident edge, irrespective of the input arc direction.
    root_row = rotations[sink]
    if not root_row:
        return None
    root_anchor = root_row[0]
    u, v, _ = edges[root_anchor]
    root_dart = 2 * root_anchor + (1 if sink == v else 0)
    infinity = right_face[root_dart]
    return {
        "n": n,
        "m": m,
        "source": source,
        "sink": sink,
        "edges": edges,
        "rotations": rotations,
        "left_face": left_face,
        "right_face": right_face,
        "infinity": infinity,
        "root_anchor": root_anchor,
    }


def _solve(graph) -> int:
    n = graph["n"]
    m = graph["m"]
    source = graph["source"]
    sink = graph["sink"]
    edges = graph["edges"]
    left_face = graph["left_face"]
    right_face = graph["right_face"]
    infinity = graph["infinity"]
    face_count = m - n + 2

    # Dijkstra runs toward f_infinity on reverse dual darts. The zero-length
    # reverse primal dart and the capacity-length forward dart imply
    # 0 <= phi[L(a)]-phi[R(a)] <= capacity(a).
    dual: list[list[tuple[int, int]]] = [[] for _ in range(face_count)]
    for dart in range(2 * m):
        edge_id = dart // 2
        length = edges[edge_id][2] if dart % 2 == 0 else 0
        dual[right_face[dart]].append((left_face[dart], length))
    inf = 1 << 60
    distance = [inf] * face_count
    done = [False] * face_count
    distance[infinity] = 0
    for _ in range(face_count):
        current = -1
        for face in range(face_count):
            if not done[face] and (current < 0 or distance[face] < distance[current]):
                current = face
        if current < 0 or distance[current] == inf:
            break
        done[current] = True
        for neighbor, length in dual[current]:
            candidate = distance[current] + length
            if candidate < distance[neighbor]:
                distance[neighbor] = candidate

    residual = [[0] * n for _ in range(n)]
    for edge_id, (u, v, capacity) in enumerate(edges):
        eta = distance[left_face[2 * edge_id]] - distance[right_face[2 * edge_id]]
        if not 0 <= eta <= capacity:
            return -1
        residual[u][v] += capacity - eta
        residual[v][u] += eta

    # Pick a canonical boundary dart at t. Rotations are supplied CCW; the
    # right-face test is evaluated in the same dart convention as face walks.
    root_anchor = graph["root_anchor"]

    total = 0
    while True:
        seen = [False] * n
        parent = [-1] * n
        parent_edge = [-1] * n
        seen[sink] = True

        def visit(vertex: int, anchor_edge: int, root: bool = False) -> None:
            row = graph["rotations"][vertex]
            degree = len(row)
            if not degree:
                return
            anchor_position = row.index(anchor_edge)
            start_offset = 0 if root else 1
            for step in range(start_offset, start_offset + degree):
                edge_id = row[(anchor_position + step) % degree]
                u, v, _ = edges[edge_id]
                neighbor = v if u == vertex else u
                # Search in the residual graph with every arc reversed.
                if not seen[neighbor] and residual[neighbor][vertex] > 0:
                    seen[neighbor] = True
                    parent[neighbor] = vertex
                    parent_edge[neighbor] = edge_id
                    visit(neighbor, edge_id)

        visit(sink, root_anchor, True)
        if not seen[source]:
            return total
        delta = 1 << 60
        vertex = source
        while vertex != sink:
            next_vertex = parent[vertex]
            delta = min(delta, residual[vertex][next_vertex])
            vertex = next_vertex
        vertex = source
        while vertex != sink:
            next_vertex = parent[vertex]
            residual[vertex][next_vertex] -= delta
            residual[next_vertex][vertex] += delta
            vertex = next_vertex
        total += delta


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    graph = _decode(values)
    if graph is None:
        return -1, b""
    value = _solve(graph)
    if value < 0:
        return -1, b""
    payload = struct.pack("<q", value)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
