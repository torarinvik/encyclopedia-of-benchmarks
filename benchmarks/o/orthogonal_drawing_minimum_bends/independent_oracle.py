"""Independent Bellman-Ford reference for the bounded bend-flow profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 16
MAX_FACES = 10
MAX_VALID_INPUT_LENGTH = 4 + 4 * MAX_M + MAX_FACES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8


def _components(adjacency: list[set[int]], removed: int = -1) -> set[int]:
    start = next(vertex for vertex in range(len(adjacency)) if vertex != removed)
    reached = {start}
    todo = [start]
    while todo:
        vertex = todo.pop()
        for neighbor in adjacency[vertex]:
            if neighbor != removed and neighbor not in reached:
                reached.add(neighbor)
                todo.append(neighbor)
    return reached


def _read(values: Sequence[int]):
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values):
        return None
    n, m, f, outside = values[:4]
    if not (3 <= n <= MAX_N and n <= m <= MAX_M and 2 <= f <= MAX_FACES):
        return None
    if f != m - n + 2 or not 0 <= outside < f:
        return None
    p = 4
    edge_set: set[tuple[int, int]] = set()
    neighbors = [set() for _ in range(n)]
    for _ in range(m):
        if p + 1 >= len(values):
            return None
        a, b = values[p], values[p + 1]
        p += 2
        if not (0 <= a < b < n) or (a, b) in edge_set:
            return None
        edge_set.add((a, b))
        neighbors[a].add(b)
        neighbors[b].add(a)
    if list(sorted(edge_set)) != [tuple(values[4 + 2*i:6 + 2*i]) for i in range(m)]:
        return None
    if any(not 2 <= len(row) <= 4 for row in neighbors):
        return None
    if len(_components(neighbors)) != n:
        return None
    if any(len(_components(neighbors, v)) != n - 1 for v in range(n)):
        return None

    walks: list[list[int]] = []
    dart_count: dict[tuple[int, int], int] = {}
    for _ in range(f):
        if p >= len(values):
            return None
        width = values[p]
        p += 1
        if width < 3 or width > n or p + width > len(values):
            return None
        walk = list(values[p:p + width])
        p += width
        if len(set(walk)) != width or any(not 0 <= x < n for x in walk):
            return None
        for i, a in enumerate(walk):
            b = walk[(i + 1) % width]
            if (min(a, b), max(a, b)) not in edge_set:
                return None
            dart_count[(a, b)] = dart_count.get((a, b), 0) + 1
        walks.append(walk)
    if p != len(values):
        return None
    if any(dart_count.get((a, b), 0) != 1 or dart_count.get((b, a), 0) != 1
           for a, b in edge_set):
        return None
    link_neighbors = [[set() for _ in range(n)] for _ in range(n)]
    link_degree = [[0] * n for _ in range(n)]
    for walk in walks:
        for i, vertex in enumerate(walk):
            previous = walk[(i - 1) % len(walk)]
            following = walk[(i + 1) % len(walk)]
            if previous == following:
                return None
            link_neighbors[vertex][previous].add(following)
            link_neighbors[vertex][following].add(previous)
            link_degree[vertex][previous] += 1
            link_degree[vertex][following] += 1
    for vertex, row in enumerate(neighbors):
        if any(link_degree[vertex][other] != 2 for other in row):
            return None
        if any(link_degree[vertex][other] for other in range(n) if other not in row):
            return None
        seed = min(row)
        component = {seed}
        frontier = [seed]
        while frontier:
            current = frontier.pop()
            for other in link_neighbors[vertex][current]:
                if other not in component:
                    component.add(other)
                    frontier.append(other)
        if component != row:
            return None
    if n - m + f != 2:
        return None
    incident: dict[tuple[int, int], list[int]] = {e: [] for e in edge_set}
    for face, walk in enumerate(walks):
        for i, a in enumerate(walk):
            b = walk[(i + 1) % len(walk)]
            incident[(min(a, b), max(a, b))].append(face)
    if any(len(fs) != 2 or fs[0] == fs[1] for fs in incident.values()):
        return None
    return n, edge_set, walks, outside, incident


def _solve(instance) -> int | None:
    n, edges, faces, outside, incident = instance
    f = len(faces)
    nodes = n + f
    source, sink = nodes, nodes + 1
    vertex_count = nodes + 2
    # Each record is [to, reverse-index, residual-capacity, cost].
    residual: list[list[list[int]]] = [[] for _ in range(vertex_count)]

    def connect(a: int, b: int, cap: int, price: int) -> None:
        rev_a = len(residual[a])
        rev_b = len(residual[b])
        residual[a].append([b, rev_b, cap, price])
        residual[b].append([a, rev_a, 0, -price])

    net = [4] * n + [0] * f
    for face_id, polygon in enumerate(faces):
        demand = 2 * len(polygon) - 4
        if face_id == outside:
            demand += 8
        net[n + face_id] -= demand
        for corner in polygon:
            net[corner] -= 1
            net[n + face_id] += 1
            connect(corner, n + face_id, 4 * n, 0)
    for adjacent_faces in incident.values():
        a, b = adjacent_faces
        connect(n + a, n + b, 4 * n, 1)
        connect(n + b, n + a, 4 * n, 1)

    need = 0
    for vertex, excess in enumerate(net):
        if excess > 0:
            connect(source, vertex, excess, 0)
            need += excess
        elif excess < 0:
            connect(vertex, sink, -excess, 0)

    sent = 0
    charge = 0
    while sent < need:
        dist: list[int | None] = [None] * vertex_count
        pred: list[tuple[int, int] | None] = [None] * vertex_count
        dist[source] = 0
        for _ in range(vertex_count - 1):
            changed = False
            for u in range(vertex_count):
                if dist[u] is None:
                    continue
                for edge_id, arc in enumerate(residual[u]):
                    v, _, cap, cost = arc
                    alt = dist[u] + cost
                    if cap and (dist[v] is None or alt < dist[v]):
                        dist[v] = alt
                        pred[v] = (u, edge_id)
                        changed = True
            if not changed:
                break
        if dist[sink] is None:
            return None
        delta = need - sent
        path_price = 0
        at = sink
        while at != source:
            step = pred[at]
            if step is None:
                return None
            u, edge_id = step
            arc = residual[u][edge_id]
            delta = min(delta, arc[2])
            path_price += arc[3]
            at = u
        at = sink
        while at != source:
            u, edge_id = pred[at]  # type: ignore[misc]
            arc = residual[u][edge_id]
            v, rev = arc[0], arc[1]
            arc[2] -= delta
            residual[v][rev][2] += delta
            at = u
        sent += delta
        charge += delta * path_price
    return charge


def expected_output(values: Sequence[int] | None, *, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))
            or (input_length is not None and type(input_length) is not int)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if not isinstance(values, Sequence):
        return -1, b""
    if input_length is not None:
        if input_length < 0 or input_length > len(values):
            return -1, b""
        values = values[:input_length]
    instance = _read(values)
    if instance is None:
        return -1, b""
    optimum = _solve(instance)
    if optimum is None:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    return MAX_OUTPUT_BYTES, struct.pack("<q", optimum)
