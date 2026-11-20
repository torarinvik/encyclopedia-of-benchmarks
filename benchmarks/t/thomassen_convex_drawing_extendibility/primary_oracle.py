"""Primary bounded reference for Thomassen's extendibility conditions."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_M = 18
MAX_F = 12
MAX_VALID_INPUT_LENGTH = 92
MAX_INPUT_LENGTH = 93
WORKSPACE_BYTES = 16384
INF = 10_000


def _decode(values: Sequence[int]):
    if not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    n, m, f, outer, side_count = values[:5]
    if not 3 <= n <= MAX_N or not n <= m <= min(MAX_M, 3 * n - 6):
        return None
    if not 2 <= f <= MAX_F or f != m - n + 2:
        return None
    if not 3 <= side_count <= n or not 0 <= outer < f:
        return None
    p = 5
    edges: list[tuple[int, int]] = []
    adjacency = [[False] * n for _ in range(n)]
    for _ in range(m):
        if p + 2 > len(values):
            return None
        u, v = values[p:p + 2]
        p += 2
        if not 0 <= u < v < n or adjacency[u][v]:
            return None
        adjacency[u][v] = adjacency[v][u] = True
        edges.append((u, v))
    if edges != sorted(edges):
        return None

    faces: list[list[int]] = []
    dart_use = [[0] * n for _ in range(n)]
    for _ in range(f):
        if p >= len(values):
            return None
        width = values[p]
        p += 1
        if not 3 <= width <= n or p + width > len(values):
            return None
        cycle = list(values[p:p + width])
        p += width
        if len(set(cycle)) != width or any(not 0 <= v < n for v in cycle):
            return None
        for i, u in enumerate(cycle):
            v = cycle[(i + 1) % width]
            if not adjacency[u][v]:
                return None
            dart_use[u][v] += 1
        faces.append(cycle)
    if outer >= len(faces):
        return None
    outer_cycle = faces[outer]
    if p + side_count > len(values):
        return None
    apices = list(values[p:p + side_count])
    p += side_count
    if p != len(values):
        return None
    if (any(dart_use[u][v] != 1 or dart_use[v][u] != 1 for u, v in edges)
            or n - m + f != 2):
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

    seen = {0}
    stack = [0]
    while stack:
        u = stack.pop()
        for v in range(n):
            if adjacency[u][v] and v not in seen:
                seen.add(v)
                stack.append(v)
    if len(seen) != n or any(not connected_without(v) for v in range(n)):
        return None

    # A sphere embedding has one cyclic link per vertex.  Preserve the two
    # parallel link edges at graph-degree-two vertices via corner degrees.
    link_adjacency = [[set() for _ in range(n)] for _ in range(n)]
    link_degree = [[0] * n for _ in range(n)]
    for cycle in faces:
        width = len(cycle)
        for i, vertex in enumerate(cycle):
            before = cycle[(i - 1) % width]
            after = cycle[(i + 1) % width]
            if before == after:
                return None
            link_adjacency[vertex][before].add(after)
            link_adjacency[vertex][after].add(before)
            link_degree[vertex][before] += 1
            link_degree[vertex][after] += 1
    for vertex in range(n):
        incident = {neighbor for neighbor in range(n) if adjacency[vertex][neighbor]}
        if any(link_degree[vertex][neighbor] != 2 for neighbor in incident):
            return None
        if any(link_degree[vertex][neighbor] != 0 for neighbor in range(n)
               if neighbor not in incident):
            return None
        seed = min(incident)
        reached = {seed}
        pending = [seed]
        while pending:
            current = pending.pop()
            for neighbor in link_adjacency[vertex][current]:
                if neighbor not in reached:
                    reached.add(neighbor)
                    pending.append(neighbor)
        if reached != incident:
            return None

    edge_faces = {edge: [] for edge in edges}
    for face_id, cycle in enumerate(faces):
        for i, u in enumerate(cycle):
            v = cycle[(i + 1) % len(cycle)]
            edge_faces[(min(u, v), max(u, v))].append(face_id)
    if any(len(pair) != 2 or pair[0] == pair[1] for pair in edge_faces.values()):
        return None
    if (len(outer_cycle) < side_count or len(set(apices)) != side_count
            or any(not 0 <= position < len(outer_cycle) for position in apices)
            or apices != sorted(apices)):
        return None

    outer_vertices = set(outer_cycle)
    outer_edges = {(min(outer_cycle[i], outer_cycle[(i + 1) % len(outer_cycle)]),
                    max(outer_cycle[i], outer_cycle[(i + 1) % len(outer_cycle)]))
                   for i in range(len(outer_cycle))}
    side_vertices: list[set[int]] = []
    for i, start in enumerate(apices):
        end = apices[(i + 1) % side_count]
        path: set[int] = set()
        at = start
        while True:
            path.add(outer_cycle[at])
            if at == end:
                break
            at = (at + 1) % len(outer_cycle)
        side_vertices.append(path)
    degree = [sum(row) for row in adjacency]
    return n, edges, adjacency, faces, outer, outer_cycle, outer_vertices, outer_edges, side_vertices, degree


def _three_outer_paths(n: int, adjacency: list[list[bool]], outer: set[int], root: int) -> bool:
    source, sink = 2 * n, 2 * n + 1
    node_count = 2 * n + 2
    residual = [[0] * node_count for _ in range(node_count)]

    def add_arc(u: int, v: int, cap: int) -> None:
        residual[u][v] += cap

    for vertex in range(n):
        if vertex != root:
            add_arc(2 * vertex, 2 * vertex + 1, 1)
    for u in range(n):
        for v in range(u + 1, n):
            if not adjacency[u][v]:
                continue
            if u == root:
                add_arc(source, 2 * v, 1)
            elif v == root:
                add_arc(source, 2 * u, 1)
            else:
                add_arc(2 * u + 1, 2 * v, 1)
                add_arc(2 * v + 1, 2 * u, 1)
    for vertex in outer:
        if vertex != root:
            add_arc(2 * vertex + 1, sink, 1)

    flow = 0
    while flow < 3:
        parent = [-1] * node_count
        parent[source] = source
        queue = [source]
        for u in queue:
            for v, capacity in enumerate(residual[u]):
                if capacity > 0 and parent[v] < 0:
                    parent[v] = u
                    queue.append(v)
                    if v == sink:
                        break
            if parent[sink] >= 0:
                break
        if parent[sink] < 0:
            return False
        v = sink
        while v != source:
            u = parent[v]
            residual[u][v] -= 1
            residual[v][u] += 1
            v = u
        flow += 1
    return True


def _condition_three(n: int, inner_adjacency: list[list[bool]], degree: list[int]) -> bool:
    for start in range(n):
        size = 1 << n
        dp = [[INF] * n for _ in range(size)]
        initial = 1 << start
        dp[initial][start] = int(degree[start] >= 3)
        for mask in range(initial, size):
            if not mask & initial:
                continue
            for last in range(start, n):
                used = dp[mask][last]
                if used == INF:
                    continue
                if mask.bit_count() >= 3 and inner_adjacency[last][start] and used < 3:
                    return False
                for nxt in range(start + 1, n):
                    bit = 1 << nxt
                    if mask & bit or not inner_adjacency[last][nxt]:
                        continue
                    next_mask = mask | bit
                    value = used + int(degree[nxt] >= 3)
                    if value < dp[next_mask][nxt]:
                        dp[next_mask][nxt] = value
    return True


def _extendible(instance) -> bool:
    n, edges, adjacency, faces, outer, outer_cycle, outer_vertices, outer_edges, sides, degree = instance
    for vertex in range(n):
        if vertex not in outer_vertices and degree[vertex] >= 3:
            if not _three_outer_paths(n, adjacency, outer_vertices, vertex):
                return False

    interior = set(range(n)) - outer_vertices
    seen: set[int] = set()
    for seed in interior:
        if seed in seen:
            continue
        component = {seed}
        seen.add(seed)
        stack = [seed]
        boundary_neighbors: set[int] = set()
        while stack:
            u = stack.pop()
            for v in range(n):
                if not adjacency[u][v]:
                    continue
                if v in outer_vertices:
                    boundary_neighbors.add(v)
                elif v not in seen:
                    seen.add(v)
                    component.add(v)
                    stack.append(v)
        if any(boundary_neighbors and boundary_neighbors <= side for side in sides):
            return False

    for u, v in edges:
        key = (u, v)
        if key not in outer_edges and any(u in side and v in side for side in sides):
            return False

    inner_adjacency = [[adjacency[u][v] and
                        (min(u, v), max(u, v)) not in outer_edges
                        for v in range(n)] for u in range(n)]
    return _condition_three(n, inner_adjacency, degree)


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, Sequence):
        return -1
    if input_length is not None:
        if type(input_length) is not int or not 0 <= input_length <= len(values):
            return -1
        values = values[:input_length]
    instance = _decode(values)
    if instance is None:
        return -1
    return 1 if _extendible(instance) else 0
