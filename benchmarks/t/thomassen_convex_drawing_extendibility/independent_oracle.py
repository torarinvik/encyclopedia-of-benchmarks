"""Independent path-enumeration/cycle-enumeration reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_M = 18
MAX_F = 12
MAX_INPUT_LENGTH = 93


def _read(values: Sequence[int]):
    if not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m, face_count, outer_id, side_count = values[:5]
    if not 3 <= n <= MAX_N or not n <= m <= min(MAX_M, 3 * n - 6):
        return None
    if not 2 <= face_count <= MAX_F or face_count != m - n + 2:
        return None
    if not 0 <= outer_id < face_count or not 3 <= side_count <= n:
        return None
    cursor = 5
    edge_list: list[tuple[int, int]] = []
    neighbor_sets = [set() for _ in range(n)]
    for _ in range(m):
        if cursor + 2 > len(values):
            return None
        a, b = values[cursor], values[cursor + 1]
        cursor += 2
        if a < 0 or b >= n or a >= b or b in neighbor_sets[a]:
            return None
        neighbor_sets[a].add(b)
        neighbor_sets[b].add(a)
        edge_list.append((a, b))
    if edge_list != sorted(edge_list) or any(len(row) < 2 for row in neighbor_sets):
        return None

    walks: list[list[int]] = []
    darts: dict[tuple[int, int], int] = {}
    for _ in range(face_count):
        if cursor >= len(values):
            return None
        k = values[cursor]
        cursor += 1
        if not 3 <= k <= n or cursor + k > len(values):
            return None
        cycle = list(values[cursor:cursor + k])
        cursor += k
        if len(set(cycle)) != k or any(not 0 <= x < n for x in cycle):
            return None
        for j, a in enumerate(cycle):
            b = cycle[(j + 1) % k]
            if b not in neighbor_sets[a]:
                return None
            darts[(a, b)] = darts.get((a, b), 0) + 1
        walks.append(cycle)
    if cursor + side_count != len(values):
        return None
    positions = list(values[cursor:])
    outer_cycle = walks[outer_id]
    if (len(outer_cycle) < side_count or positions != sorted(positions)
            or len(set(positions)) != side_count
            or any(not 0 <= p < len(outer_cycle) for p in positions)):
        return None
    if any(darts.get((a, b), 0) != 1 or darts.get((b, a), 0) != 1
           for a, b in edge_list):
        return None

    def component_without(deleted: int = -1) -> set[int]:
        start = next(v for v in range(n) if v != deleted)
        reached = {start}
        todo = [start]
        while todo:
            u = todo.pop()
            for v in neighbor_sets[u]:
                if v != deleted and v not in reached:
                    reached.add(v)
                    todo.append(v)
        return reached

    if len(component_without()) != n or any(len(component_without(v)) != n - 1 for v in range(n)):
        return None
    if n - m + face_count != 2:
        return None
    corners: list[list[set[int]]] = [[set() for _ in range(n)] for _ in range(n)]
    corner_degree = [[0] * n for _ in range(n)]
    for walk in walks:
        for i, vertex in enumerate(walk):
            previous = walk[(i - 1) % len(walk)]
            following = walk[(i + 1) % len(walk)]
            if previous == following:
                return None
            corners[vertex][previous].add(following)
            corners[vertex][following].add(previous)
            corner_degree[vertex][previous] += 1
            corner_degree[vertex][following] += 1
    for vertex, row in enumerate(neighbor_sets):
        if any(corner_degree[vertex][neighbor] != 2 for neighbor in row):
            return None
        if any(corner_degree[vertex][neighbor] for neighbor in range(n) if neighbor not in row):
            return None
        reached = {next(iter(row))}
        pending = list(reached)
        while pending:
            neighbor = pending.pop()
            for other in corners[vertex][neighbor]:
                if other not in reached:
                    reached.add(other)
                    pending.append(other)
        if reached != row:
            return None
    edge_faces: dict[tuple[int, int], list[int]] = {edge: [] for edge in edge_list}
    for face_id, cycle in enumerate(walks):
        for j, a in enumerate(cycle):
            b = cycle[(j + 1) % len(cycle)]
            edge_faces[(min(a, b), max(a, b))].append(face_id)
    if any(len(ids) != 2 or ids[0] == ids[1] for ids in edge_faces.values()):
        return None
    apex_vertices = [outer_cycle[position] for position in positions]
    side_sets: list[set[int]] = []
    for i, start in enumerate(positions):
        end = positions[(i + 1) % side_count]
        side: set[int] = set()
        at = start
        while True:
            side.add(outer_cycle[at])
            if at == end:
                break
            at = (at + 1) % len(outer_cycle)
        side_sets.append(side)
    outer_edges = {(min(walks[outer_id][j], walks[outer_id][(j + 1) % len(outer_cycle)]),
                    max(walks[outer_id][j], walks[outer_id][(j + 1) % len(outer_cycle)]))
                   for j in range(len(outer_cycle))}
    degree = [len(row) for row in neighbor_sets]
    return n, edge_list, neighbor_sets, outer_cycle, set(outer_cycle), outer_edges, side_sets, degree


def _three_paths(root: int, graph: list[set[int]], boundary: set[int]) -> bool:
    candidates: list[frozenset[int]] = []
    visited = {root}
    path: list[int] = []

    def enumerate_paths(vertex: int) -> None:
        for nxt in graph[vertex]:
            if nxt in visited:
                continue
            visited.add(nxt)
            path.append(nxt)
            if nxt in boundary:
                candidates.append(frozenset(path))
            else:
                enumerate_paths(nxt)
            path.pop()
            visited.remove(nxt)

    enumerate_paths(root)
    unique_paths = list(dict.fromkeys(candidates))
    for i, first in enumerate(unique_paths):
        for j in range(i + 1, len(unique_paths)):
            second = unique_paths[j]
            if first & second:
                continue
            for third in unique_paths[j + 1:]:
                if not first & third and not second & third:
                    return True
    return False


def _bad_inner_cycle(n: int, graph: list[set[int]], high: list[bool]) -> bool:
    for start in range(n):
        visited = {start}
        path = [start]

        def search(vertex: int) -> bool:
            if len(path) >= 3 and start in graph[vertex]:
                if sum(high[v] for v in path) < 3:
                    return True
            for nxt in graph[vertex]:
                if nxt <= start or nxt in visited:
                    continue
                visited.add(nxt)
                path.append(nxt)
                if search(nxt):
                    return True
                path.pop()
                visited.remove(nxt)
            return False

        if search(start):
            return True
    return False


def _test(instance) -> bool:
    n, edge_list, adjacency, outer_cycle, outer_vertices, outer_edges, sides, degree = instance
    for vertex in range(n):
        if vertex not in outer_vertices and degree[vertex] >= 3:
            if not _three_paths(vertex, adjacency, outer_vertices):
                return False

    remaining = set(range(n)) - outer_vertices
    while remaining:
        seed = min(remaining)
        component = {seed}
        todo = [seed]
        remaining.remove(seed)
        border: set[int] = set()
        while todo:
            u = todo.pop()
            for v in adjacency[u]:
                if v in outer_vertices:
                    border.add(v)
                elif v in remaining:
                    remaining.remove(v)
                    component.add(v)
                    todo.append(v)
        if any(border and border <= side for side in sides):
            return False

    for u, v in edge_list:
        if (min(u, v), max(u, v)) not in outer_edges:
            if any(u in side and v in side for side in sides):
                return False
    inner_graph = [set() for _ in range(n)]
    for u, v in edge_list:
        if (u, v) not in outer_edges:
            inner_graph[u].add(v)
            inner_graph[v].add(u)
    return not _bad_inner_cycle(n, inner_graph, [d >= 3 for d in degree])


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, Sequence):
        return -1
    if input_length is not None:
        if type(input_length) is not int or not 0 <= input_length <= len(values):
            return -1
        values = values[:input_length]
    instance = _read(values)
    if instance is None:
        return -1
    return 1 if _test(instance) else 0
