"""Bounded planarity test by exhaustive component rotation systems."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence
from itertools import permutations, product

MIN_VERTICES = 1
MAX_VERTICES = 6
MAX_EDGES = 15
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[0], values[1]
    if not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for at in range(2, len(values), 2):
        u, v = values[at], values[at + 1]
        if not 0 <= u < v < n or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges


def _component_has_spherical_rotation(
    component: list[int], component_edges: list[int],
    neighbors: list[list[int]], edge_ids: list[list[int]],
    edge_ends: list[tuple[int, int]],
) -> bool:
    if len(component) == 1:
        return True
    rotation_choices = []
    for vertex in component:
        row = neighbors[vertex]
        if len(row) <= 1:
            rotation_choices.append([tuple(row)])
        else:
            rotation_choices.append(
                [(row[0],) + tail for tail in permutations(row[1:])]
            )
    dart_count = 2 * len(edge_ends)
    for selected_orders in product(*rotation_choices):
        successor = [-1] * dart_count
        for vertex, order in zip(component, selected_orders):
            if not order:
                continue
            for index, neighbor in enumerate(order):
                next_neighbor = order[(index + 1) % len(order)]
                edge = edge_ids[vertex][neighbor]
                next_edge = edge_ids[vertex][next_neighbor]
                dart = 2 * edge + (0 if edge_ends[edge][0] == vertex else 1)
                next_dart = 2 * next_edge + (0 if edge_ends[next_edge][0] == vertex else 1)
                successor[dart] = next_dart
        used = [False] * dart_count
        faces = 0
        for edge in component_edges:
            for start in (2 * edge, 2 * edge + 1):
                if used[start]:
                    continue
                faces += 1
                dart = start
                while not used[dart]:
                    used[dart] = True
                    dart = successor[dart ^ 1]
        if len(component) - len(component_edges) + faces == 2:
            return True
    return False


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, edges = parsed
    m = len(edges)
    if n >= 3 and m > 3 * n - 6:
        return 0

    neighbors = [[] for _ in range(n)]
    edge_ids = [[-1] * n for _ in range(n)]
    for edge, (u, v) in enumerate(edges):
        neighbors[u].append(v)
        neighbors[v].append(u)
        edge_ids[u][v] = edge_ids[v][u] = edge
    for row in neighbors:
        row.sort()

    seen = [False] * n
    for root in range(n):
        if seen[root]:
            continue
        queue = deque([root])
        seen[root] = True
        component = []
        while queue:
            vertex = queue.popleft()
            component.append(vertex)
            for neighbor in neighbors[vertex]:
                if not seen[neighbor]:
                    seen[neighbor] = True
                    queue.append(neighbor)
        component_set = set(component)
        component_edges = [
            edge for edge, (u, v) in enumerate(edges)
            if u in component_set and v in component_set
        ]
        if len(component) >= 3 and len(component_edges) > 3 * len(component) - 6:
            return 0
        if not _component_has_spherical_rotation(
                component, component_edges, neighbors, edge_ids, edges):
            return 0
    return 1
