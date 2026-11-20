"""Seeded recursive Boruvka-sampling MSF reference for the bounded KKT profile."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_VERTICES = 16
MAX_EDGES = 16
MAX_WEIGHT = 255
MAX_VALID_INPUT_LENGTH = 51
MAX_PARSEABLE_INPUT_LENGTH = 52
MASK64 = (1 << 64) - 1

Edge = tuple[int, int, int, int]  # local u, local v, weight, original edge id


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[Edge]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, seed = values[:3]
    if (not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES
            or not 0 <= seed < (1 << 63)
            or len(values) != 3 + 3 * m or len(values) > MAX_VALID_INPUT_LENGTH):
        return None
    edges: list[Edge] = []
    pairs: set[tuple[int, int]] = set()
    for edge_id in range(m):
        u, v, weight = values[3 + 3 * edge_id:6 + 3 * edge_id]
        if not 0 <= u < v < n or not 0 <= weight <= MAX_WEIGHT or (u, v) in pairs:
            return None
        pairs.add((u, v))
        edges.append((u, v, weight, edge_id))
    return n, seed, edges


def _next_splitmix_bit(state: list[int]) -> int:
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & MASK64
    value = state[0]
    value = ((value ^ (value >> 30)) * 0xBF58476D1CE4E5B9) & MASK64
    value = ((value ^ (value >> 27)) * 0x94D049BB133111EB) & MASK64
    value ^= value >> 31
    return value & 1


def _find(parent: list[int], vertex: int) -> int:
    while parent[vertex] != vertex:
        parent[vertex] = parent[parent[vertex]]
        vertex = parent[vertex]
    return vertex


def _contract_one_boruvka_phase(n: int, edges: list[Edge]) -> tuple[int, list[Edge], int]:
    chosen: list[Edge | None] = [None] * n
    for edge in edges:
        u, v, _, _ = edge
        if chosen[u] is None or edge[2:] < chosen[u][2:]:
            chosen[u] = edge
        if chosen[v] is None or edge[2:] < chosen[v][2:]:
            chosen[v] = edge

    parent = list(range(n))

    def union(left: int, right: int) -> None:
        root_left = _find(parent, left)
        root_right = _find(parent, right)
        if root_left != root_right:
            parent[root_right] = root_left

    selected_ids: set[int] = set()
    for edge in chosen:
        if edge is not None:
            selected_ids.add(edge[3])
            union(edge[0], edge[1])

    component_ids: dict[int, int] = {}
    component_of = [0] * n
    for vertex in range(n):
        root = _find(parent, vertex)
        if root not in component_ids:
            component_ids[root] = len(component_ids)
        component_of[vertex] = component_ids[root]

    best_by_pair: dict[tuple[int, int], Edge] = {}
    for u, v, weight, edge_id in edges:
        new_u, new_v = component_of[u], component_of[v]
        if new_u == new_v:
            continue
        if new_u > new_v:
            new_u, new_v = new_v, new_u
        pair = (new_u, new_v)
        candidate = (new_u, new_v, weight, edge_id)
        if pair not in best_by_pair or candidate[2:] < best_by_pair[pair][2:]:
            best_by_pair[pair] = candidate

    selected_mask = sum(1 << edge_id for edge_id in selected_ids)
    return len(component_ids), list(best_by_pair.values()), selected_mask


def _path_max_key(n: int, edges: list[Edge], forest_mask: int,
                  source: int, target: int) -> tuple[bool, tuple[int, int] | None]:
    adjacency: list[list[tuple[int, Edge]]] = [[] for _ in range(n)]
    for edge in edges:
        u, v, _, edge_id = edge
        if forest_mask & (1 << edge_id):
            adjacency[u].append((v, edge))
            adjacency[v].append((u, edge))

    parent_vertex = [-1] * n
    parent_edge: list[Edge | None] = [None] * n
    parent_vertex[source] = source
    todo = [source]
    while todo and parent_vertex[target] < 0:
        vertex = todo.pop()
        for neighbor, edge in adjacency[vertex]:
            if parent_vertex[neighbor] < 0:
                parent_vertex[neighbor] = vertex
                parent_edge[neighbor] = edge
                todo.append(neighbor)
    if parent_vertex[target] < 0:
        return False, None

    maximum: tuple[int, int] | None = None
    vertex = target
    while vertex != source:
        edge = parent_edge[vertex]
        assert edge is not None
        key = edge[2:]
        if maximum is None or key > maximum:
            maximum = key
        vertex = parent_vertex[vertex]
    return True, maximum


def _kkt(n: int, edges: list[Edge], state: list[int]) -> int:
    if not edges:
        return 0

    selected_mask = 0
    for _ in range(2):
        n, edges, selected = _contract_one_boruvka_phase(n, edges)
        selected_mask |= selected
        if not edges:
            return selected_mask

    sampled: list[Edge] = []
    for edge in sorted(edges, key=lambda item: item[2:]):
        if _next_splitmix_bit(state):
            sampled.append(edge)
    sample_forest = _kkt(n, sampled, state)

    light_edges: list[Edge] = []
    for edge in edges:
        connected, path_maximum = _path_max_key(n, edges, sample_forest, edge[0], edge[1])
        if not connected or path_maximum is None or edge[2:] <= path_maximum:
            light_edges.append(edge)

    return selected_mask | _kkt(n, light_edges, state)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or values is None or not isinstance(values, (tuple, list))):
        return INVALID_RESULT
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, seed, edges = parsed
    return _kkt(n, edges, [seed])
