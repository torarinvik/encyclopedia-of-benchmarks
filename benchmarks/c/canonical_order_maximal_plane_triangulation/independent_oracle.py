"""Independent bounded oracle by recursive shelling enumeration and validation."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT_LENGTH = 49
MAX_OUTPUT_BYTES = 72


def _load(values: Sequence[int]):
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, first_root, second_root, last_root = values[:4]
    if (not 3 <= n <= MAX_N or len({first_root, second_root, last_root}) != 3
            or any(not 0 <= vertex < n for vertex in (first_root, second_root, last_root))):
        return None
    rotations: list[list[int]] = []
    cursor = 4
    for vertex in range(n):
        if cursor == len(values):
            return None
        arity = values[cursor]
        cursor += 1
        if not 2 <= arity < n or cursor + arity > len(values):
            return None
        cycle = list(values[cursor:cursor + arity])
        cursor += arity
        if len(set(cycle)) != arity or any(x == vertex or not 0 <= x < n for x in cycle):
            return None
        rotations.append(cycle)
    if cursor != len(values):
        return None
    edge = [[False] * n for _ in range(n)]
    if sum(map(len, rotations)) != 6 * n - 12:
        return None
    for vertex, cycle in enumerate(rotations):
        for neighbor in cycle:
            edge[vertex][neighbor] = True
    if any(edge[a][b] != edge[b][a] for a in range(n) for b in range(n)):
        return None
    if sum(edge[a][b] for a in range(n) for b in range(a + 1, n)) != 3 * n - 6:
        return None
    reached = {0}
    stack = [0]
    while stack:
        vertex = stack.pop()
        for neighbor in range(n):
            if edge[vertex][neighbor] and neighbor not in reached:
                reached.add(neighbor)
                stack.append(neighbor)
    if len(reached) != n:
        return None
    return n, first_root, second_root, last_root, rotations, edge


def _face(rotations: list[list[int]], edge: list[list[bool]], active: list[bool],
          start: tuple[int, int]) -> list[int] | None:
    source, target = start
    cycle: list[int] = []
    visited: set[tuple[int, int]] = set()
    limit = 2 * sum(map(sum, edge)) + 1
    for _ in range(limit):
        if not active[source] or not active[target] or not edge[source][target]:
            return None
        dart = (source, target)
        if dart in visited:
            return cycle if dart == start else None
        visited.add(dart)
        cycle.append(source)
        around = [neighbor for neighbor in rotations[target] if active[neighbor]]
        if len(around) < 2 or source not in around:
            return None
        following = around[(around.index(source) + 1) % len(around)]
        source, target = target, following
        if (source, target) == start:
            return cycle
    return None


def _path_to_root_edge(rotations: list[list[int]], edge: list[list[bool]],
                       active: list[bool], u: int, v: int) -> list[int] | None:
    cycle = _face(rotations, edge, active, (u, v))
    if cycle is None or len(cycle) < 3:
        return None
    path = [u, *reversed(cycle[2:]), v]
    if len(set(path)) != len(path):
        return None
    return path


def _deletion_choices(path: list[int], edge: list[list[bool]]) -> list[int]:
    chords = [(i, j) for i in range(len(path)) for j in range(i + 2, len(path))
              if not (i == 0 and j == len(path) - 1) and edge[path[i]][path[j]]]
    if not chords:
        return list(path[1:-1])
    innermost = [(a, b) for a, b in chords
                 if all((a, b) == (c, d) or not (a <= c < d <= b) for c, d in chords)]
    return sorted({path[k] for a, b in innermost for k in range(a + 1, b)})


def _two_connected(vertices: set[int], edge: list[list[bool]]) -> bool:
    def connected_without(omitted: int | None) -> bool:
        remaining = vertices - ({omitted} if omitted is not None else set())
        if len(remaining) <= 1:
            return True
        root = next(iter(remaining))
        reached = {root}
        stack = [root]
        while stack:
            vertex = stack.pop()
            for neighbor in remaining:
                if edge[vertex][neighbor] and neighbor not in reached:
                    reached.add(neighbor)
                    stack.append(neighbor)
        return reached == remaining
    return connected_without(None) and all(connected_without(vertex) for vertex in vertices)


def _is_canonical(order: list[int], u: int, v: int, w: int,
                  rotations: list[list[int]], edge: list[list[bool]]) -> bool:
    n = len(order)
    if n < 3 or order[:2] != [u, v] or order[-1] != w or len(set(order)) != n:
        return False
    for prefix_length in range(3, n):
        prefix = set(order[:prefix_length])
        path = _path_to_root_edge(rotations, edge, [node in prefix for node in range(n)], u, v)
        if path is None or not _two_connected(prefix, edge):
            return False
        added = order[prefix_length]
        if added not in path[1:-1]:
            return False
        earlier_neighbors = {node for node in prefix if edge[added][node]}
        # The source condition uses the entire u-to-v outer-boundary path,
        # including its two root endpoints; the root edge itself is excluded.
        boundary_neighbors = [node for node in path if edge[added][node]]
        if earlier_neighbors != set(boundary_neighbors) or len(boundary_neighbors) < 2:
            return False
        positions = [path.index(node) for node in boundary_neighbors]
        if max(positions) - min(positions) + 1 != len(positions):
            return False
    return True


def _find_order(values: Sequence[int]) -> list[int] | None:
    parsed = _load(values)
    if parsed is None:
        return None
    n, u, v, w, rotations, edge = parsed
    active_all = [True] * n
    faces = []
    seen_darts: set[tuple[int, int]] = set()
    for source in range(n):
        for target in range(n):
            if edge[source][target] and (source, target) not in seen_darts:
                face = _face(rotations, edge, active_all, (source, target))
                if face is None or len(face) != 3:
                    return None
                faces.append(face)
                seen_darts.update((face[i], face[(i + 1) % 3]) for i in range(3))
    if len(faces) != 2 * n - 4 or len(seen_darts) != 6 * n - 12 or _face(rotations, edge, active_all, (u, v)) != [u, v, w]:
        return None

    def explore(active: list[bool], path: list[int], reverse_order: tuple[int, ...],
                active_count: int) -> list[tuple[int, ...]]:
        if active_count == 3:
            if len(path) != 3 or path[0] != u or path[-1] != v:
                return []
            third = path[1]
            order = [u, v, third, *reversed(reverse_order)]
            return [tuple(reverse_order)] if len(order) == n and _is_canonical(
                order, u, v, w, rotations, edge) else []
        results: list[tuple[int, ...]] = []
        for candidate in _deletion_choices(path, edge):
            if candidate in (u, v, w) or not active[candidate]:
                continue
            next_active = active.copy()
            next_active[candidate] = False
            next_path = _path_to_root_edge(rotations, edge, next_active, u, v)
            if next_path is None:
                continue
            results.extend(explore(next_active, next_path, (*reverse_order, candidate), active_count - 1))
        return results

    if n == 3:
        order = [u, v, w]
        return order if _is_canonical(order, u, v, w, rotations, edge) else None
    active = [True] * n
    active[w] = False
    path = _path_to_root_edge(rotations, edge, active, u, v)
    if path is None:
        return None
    suffixes = explore(active, path, (w,), n - 1)
    if not suffixes:
        return None
    chosen = min(suffixes)
    # Enumeration chooses the lexicographically smallest reverse shelling trace.
    removed = set(chosen)
    third = next(vertex for vertex in range(n) if vertex not in removed and vertex not in (u, v))
    return [u, v, third, *reversed(chosen)]


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
    order = _find_order(values)
    if order is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", item) for item in (len(order), *order))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
