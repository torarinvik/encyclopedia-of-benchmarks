"""Horton candidate-set minimum cycle basis oracle for bounded graphs."""

from __future__ import annotations

from collections.abc import Sequence
from heapq import heappop, heappush

MIN_VERTICES = 3
MAX_VERTICES = 8
MAX_EDGES = 12
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MIN_N = MIN_VERTICES
MAX_N = MAX_VERTICES
MAX_M = MAX_EDGES
MAX_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_PARSEABLE_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[tuple[int, int, int], ...]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 2 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in values):
        return None
    n, m = values[:2]
    if not MIN_VERTICES <= n <= MAX_VERTICES or not n - 1 <= m <= MAX_EDGES:
        return None
    if m > n * (n - 1) // 2 or input_length != 2 + 3 * m:
        return None
    edges = tuple((values[2 + 3 * i], values[3 + 3 * i], values[4 + 3 * i])
                  for i in range(m))
    previous: tuple[int, int] | None = None
    for u, v, weight in edges:
        if not (0 <= u < v < n and 1 <= weight <= 9):
            return None
        pair = (u, v)
        if previous is not None and pair <= previous:
            return None
        previous = pair
    adjacency = [[] for _ in range(n)]
    for edge_id, (u, v, weight) in enumerate(edges):
        adjacency[u].append((v, edge_id, weight))
        adjacency[v].append((u, edge_id, weight))
    seen = {0}
    stack = [0]
    while stack:
        vertex = stack.pop()
        for neighbor, _, _ in adjacency[vertex]:
            if neighbor not in seen:
                seen.add(neighbor)
                stack.append(neighbor)
    if len(seen) != n:
        return None
    return n, edges


def _edge_bit(edge_id: int) -> int:
    return 1 << edge_id


def _cycle_weight(mask: int, edges: tuple[tuple[int, int, int], ...]) -> int:
    total = 0
    for edge_id, (_, _, weight) in enumerate(edges):
        if mask >> edge_id & 1:
            total += weight
    return total


def _shortest_tree(n: int, edges: tuple[tuple[int, int, int], ...], root: int
                   ) -> tuple[list[int], list[int], list[bool]]:
    adjacency: list[list[tuple[int, int, int]]] = [[] for _ in range(n)]
    for edge_id, (u, v, weight) in enumerate(edges):
        adjacency[u].append((v, edge_id, weight))
        adjacency[v].append((u, edge_id, weight))
    infinity = 1 << 60
    distance = [infinity] * n
    parent = [-1] * n
    parent_edge = [-1] * n
    settled = [False] * n
    tie_scale = (len(edges) + 1) * (1 << len(edges))
    distance[root] = 0
    queue = [(0, root)]
    while queue:
        current_distance, vertex = heappop(queue)
        if settled[vertex] or current_distance != distance[vertex]:
            continue
        settled[vertex] = True
        for neighbor, edge_id, weight in adjacency[vertex]:
            if settled[neighbor]:
                continue
            # The bounded symbolic suffix selects unique original-shortest
            # paths, while the scale also preserves total basis-weight order.
            perturbed_weight = weight * tie_scale + (1 << edge_id)
            candidate = current_distance + perturbed_weight
            old_key = (parent[neighbor], parent_edge[neighbor])
            new_key = (vertex, edge_id)
            if (candidate < distance[neighbor]
                    or (candidate == distance[neighbor] and new_key < old_key)):
                distance[neighbor] = candidate
                parent[neighbor] = vertex
                parent_edge[neighbor] = edge_id
                heappush(queue, (candidate, neighbor))
    tree_edge = [False] * len(edges)
    path_mask = [0] * n
    for vertex in range(n):
        if vertex == root:
            continue
        cursor = vertex
        steps = 0
        while cursor != root:
            edge_id = parent_edge[cursor]
            if edge_id < 0 or steps >= n:
                return [], [], []
            path_mask[vertex] |= _edge_bit(edge_id)
            cursor = parent[cursor]
            steps += 1
        if parent_edge[vertex] < 0:
            return [], [], []
        tree_edge[parent_edge[vertex]] = True
    return path_mask, parent_edge, tree_edge


def _horton_candidates(n: int, edges: tuple[tuple[int, int, int], ...]) -> list[int]:
    candidates: set[int] = set()
    for root in range(n):
        path_mask, _, tree_edge = _shortest_tree(n, edges, root)
        if not path_mask and n > 1:
            return []
        for edge_id, (u, v, _) in enumerate(edges):
            if tree_edge[edge_id]:
                continue
            cycle = path_mask[u] ^ path_mask[v] ^ _edge_bit(edge_id)
            if cycle:
                candidates.add(cycle)
    return sorted(candidates, key=lambda mask: (_cycle_weight(mask, edges), mask))


def _greedy_basis_weight(candidates: Sequence[int], edges: tuple[tuple[int, int, int], ...],
                         n: int) -> int:
    dimension = len(edges) - n + 1
    if dimension == 0:
        return 0
    pivots = [0] * len(edges)
    rank = 0
    total = 0
    for cycle in candidates:
        residual = cycle
        for bit in range(len(edges) - 1, -1, -1):
            if residual >> bit & 1:
                if pivots[bit]:
                    residual ^= pivots[bit]
                else:
                    pivots[bit] = residual
                    rank += 1
                    total += _cycle_weight(cycle, edges)
                    break
        if rank == dimension:
            return total
    return INVALID_RESULT


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, edges = parsed
    return _greedy_basis_weight(_horton_candidates(n, edges), edges, n)
