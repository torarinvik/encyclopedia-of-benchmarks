"""Primary bounded reference for minimum-bend orthogonal drawings."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 16
MAX_FACES = 10
MAX_VALID_INPUT_LENGTH = 4 + 4 * MAX_M + MAX_FACES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8
WORKSPACE_BYTES = 8192
INF = 1 << 60


def _decode(values: Sequence[int]):
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m, face_count, outer = values[:4]
    if not 3 <= n <= MAX_N or not n <= m <= MAX_M:
        return None
    if not 2 <= face_count <= MAX_FACES or face_count != m - n + 2:
        return None
    if not 0 <= outer < face_count:
        return None
    cursor = 4
    edges: list[tuple[int, int]] = []
    adjacency = [[False] * n for _ in range(n)]
    degree = [0] * n
    for _ in range(m):
        if cursor + 2 > len(values):
            return None
        u, v = values[cursor:cursor + 2]
        cursor += 2
        if not (0 <= u < v < n) or adjacency[u][v]:
            return None
        adjacency[u][v] = adjacency[v][u] = True
        degree[u] += 1
        degree[v] += 1
        edges.append((u, v))
    if any(not 2 <= d <= 4 for d in degree):
        return None
    if edges != sorted(edges):
        return None

    faces: list[list[int]] = []
    directed_uses = [[0] * n for _ in range(n)]
    for _ in range(face_count):
        if cursor >= len(values):
            return None
        length = values[cursor]
        cursor += 1
        if not 3 <= length <= n or cursor + length > len(values):
            return None
        boundary = list(values[cursor:cursor + length])
        cursor += length
        if (len(set(boundary)) != length
                or any(not 0 <= vertex < n for vertex in boundary)):
            return None
        for i, u in enumerate(boundary):
            v = boundary[(i + 1) % length]
            if not adjacency[u][v]:
                return None
            directed_uses[u][v] += 1
        faces.append(boundary)
    if cursor != len(values):
        return None
    for u, v in edges:
        if directed_uses[u][v] != 1 or directed_uses[v][u] != 1:
            return None

    # The cyclic link at each vertex must be one cycle.  A degree-two vertex
    # has a valid two-edge multicycle, so adjacency is boolean while the
    # corner incidence degree retains both parallel link edges.
    link_adj = [[set() for _ in range(n)] for _ in range(n)]
    link_degree = [[0] * n for _ in range(n)]
    for boundary in faces:
        width = len(boundary)
        for i, vertex in enumerate(boundary):
            before = boundary[(i - 1) % width]
            after = boundary[(i + 1) % width]
            if before == after:
                return None
            link_adj[vertex][before].add(after)
            link_adj[vertex][after].add(before)
            link_degree[vertex][before] += 1
            link_degree[vertex][after] += 1
    for vertex in range(n):
        incident = {neighbor for neighbor in range(n) if adjacency[vertex][neighbor]}
        if any(link_degree[vertex][neighbor] != 2 for neighbor in incident):
            return None
        if any(link_degree[vertex][neighbor] != 0 for neighbor in range(n)
               if neighbor not in incident):
            return None
        start = min(incident)
        reached = {start}
        pending = [start]
        while pending:
            current = pending.pop()
            for neighbor in link_adj[vertex][current]:
                if neighbor not in reached:
                    reached.add(neighbor)
                    pending.append(neighbor)
        if reached != incident:
            return None

    def connected_without(removed: int) -> bool:
        start = 0 if removed != 0 else 1
        seen = {start}
        stack = [start]
        while stack:
            u = stack.pop()
            for v in range(n):
                if v != removed and adjacency[u][v] and v not in seen:
                    seen.add(v)
                    stack.append(v)
        return len(seen) == n - 1

    if any(not connected_without(v) for v in range(n)):
        return None
    seen = {0}
    stack = [0]
    while stack:
        u = stack.pop()
        for v in range(n):
            if adjacency[u][v] and v not in seen:
                seen.add(v)
                stack.append(v)
    if len(seen) != n:
        return None
    if n - m + face_count != 2:
        return None

    edge_faces: dict[tuple[int, int], list[int]] = {edge: [] for edge in edges}
    for face_id, boundary in enumerate(faces):
        for i, u in enumerate(boundary):
            v = boundary[(i + 1) % len(boundary)]
            edge_faces[(min(u, v), max(u, v))].append(face_id)
    if any(len(pair) != 2 or pair[0] == pair[1] for pair in edge_faces.values()):
        return None
    return n, edges, faces, outer, edge_faces


def _minimum_cost(parsed) -> int | None:
    n, edges, faces, outer, edge_faces = parsed
    face_count = len(faces)
    original_nodes = n + face_count
    source, sink = original_nodes, original_nodes + 1
    node_count = original_nodes + 2
    graph: list[list[list[int]]] = [[] for _ in range(node_count)]

    def add_arc(u: int, v: int, capacity: int, cost: int) -> None:
        forward = [v, len(graph[v]), capacity, cost]
        reverse = [u, len(graph[u]), 0, -cost]
        graph[u].append(forward)
        graph[v].append(reverse)

    balance = [4] * n + [0] * face_count
    for face_id, boundary in enumerate(faces):
        degree = len(boundary)
        demand = 2 * degree + (4 if face_id == outer else -4)
        balance[n + face_id] -= demand
        for vertex in boundary:
            balance[vertex] -= 1
            balance[n + face_id] += 1
            add_arc(vertex, n + face_id, 4 * n, 0)
    for pair in edge_faces.values():
        left, right = pair
        add_arc(n + left, n + right, 4 * n, 1)
        add_arc(n + right, n + left, 4 * n, 1)

    required = 0
    for node, amount in enumerate(balance):
        if amount > 0:
            add_arc(source, node, amount, 0)
            required += amount
        elif amount < 0:
            add_arc(node, sink, -amount, 0)

    potential = [0] * node_count
    total_flow = 0
    total_cost = 0
    while total_flow < required:
        distance = [INF] * node_count
        parent: list[tuple[int, int] | None] = [None] * node_count
        used = [False] * node_count
        distance[source] = 0
        for _ in range(node_count):
            chosen = -1
            for vertex in range(node_count):
                if (not used[vertex] and distance[vertex] != INF
                        and (chosen < 0 or distance[vertex] < distance[chosen])):
                    chosen = vertex
            if chosen < 0:
                break
            used[chosen] = True
            for edge_index, edge in enumerate(graph[chosen]):
                to, _, capacity, cost = edge
                candidate = distance[chosen] + cost + potential[chosen] - potential[to]
                if capacity > 0 and not used[to] and candidate < distance[to]:
                    distance[to] = candidate
                    parent[to] = (chosen, edge_index)
        if distance[sink] == INF:
            return None
        for vertex, value in enumerate(distance):
            if value != INF:
                potential[vertex] += value
        amount = required - total_flow
        path_cost = 0
        vertex = sink
        while vertex != source:
            step = parent[vertex]
            if step is None:
                return None
            previous, edge_index = step
            edge = graph[previous][edge_index]
            amount = min(amount, edge[2])
            path_cost += edge[3]
            vertex = previous
        vertex = sink
        while vertex != source:
            previous, edge_index = parent[vertex]  # type: ignore[misc]
            edge = graph[previous][edge_index]
            reverse = edge[1]
            edge[2] -= amount
            graph[vertex][reverse][2] += amount
            vertex = previous
        total_flow += amount
        total_cost += amount * path_cost
    return total_cost


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
        if not 0 <= input_length <= len(values):
            return -1, b""
        values = values[:input_length]
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    result = _minimum_cost(parsed)
    if result is None:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    return MAX_OUTPUT_BYTES, struct.pack("<q", result)
