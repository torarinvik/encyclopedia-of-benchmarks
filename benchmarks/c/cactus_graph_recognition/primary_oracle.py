"""Iterative DFS cycle-ownership reference for cactus recognition."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_M = 128
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_CYCLES = MAX_M // 3
MAX_RESULT = 4 * MAX_CYCLES + 3
MAX_WORKSPACE_BYTES = 8192
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, list[list[tuple[int, int]]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, edge_count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= edge_count <= MAX_M:
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    for edge in range(edge_count):
        u, v = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        key = (min(u, v), max(u, v))
        if key in seen:
            return None
        seen.add(key)
        adjacency[u].append((v, edge))
        adjacency[v].append((u, edge))
    return n, edge_count, adjacency


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, edge_count, adjacency = parsed
    state = [0] * n
    parent = [-1] * n
    parent_edge = [-1] * n
    depth = [0] * n
    cursor = [0] * n
    cycle_of = [-1] * edge_count
    cycle_vertex_uses = [0] * n
    used = [False] * edge_count
    cycles = 0
    vertex_cactus = True

    for root in range(n):
        if state[root] != 0:
            continue
        state[root] = 1
        stack = [root]
        while stack:
            u = stack[-1]
            if cursor[u] == len(adjacency[u]):
                state[u] = 2
                stack.pop()
                continue
            v, edge = adjacency[u][cursor[u]]
            cursor[u] += 1
            if used[edge]:
                continue
            used[edge] = True
            if state[v] == 0:
                parent[v] = u
                parent_edge[v] = edge
                depth[v] = depth[u] + 1
                state[v] = 1
                stack.append(v)
            elif state[v] == 1 and depth[v] < depth[u]:
                path: list[tuple[int, int]] = []
                x = u
                while x != v:
                    tree_edge = parent_edge[x]
                    if tree_edge < 0 or cycle_of[tree_edge] != -1:
                        return 0
                    path.append((x, tree_edge))
                    x = parent[x]
                cycle_vertex_uses[u] += 1
                if cycle_vertex_uses[u] > 1:
                    vertex_cactus = False
                for vertex, tree_edge in path:
                    cycle_of[tree_edge] = cycles
                    if vertex != u:
                        cycle_vertex_uses[vertex] += 1
                        if cycle_vertex_uses[vertex] > 1:
                            vertex_cactus = False
                cycle_vertex_uses[v] += 1
                if cycle_vertex_uses[v] > 1:
                    vertex_cactus = False
                cycle_of[edge] = cycles
                cycles += 1

    return 4 * cycles + (2 if vertex_cactus else 0) + 1
