"""Independent suffix-DP reference for the canonical DAG path cover."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence
from functools import lru_cache

try:
    from .primary_oracle import (
        INVALID_RESULT, MAX_EDGES, MAX_PARSEABLE_INPUT_LENGTH,
        MAX_RESULT, MAX_VERTICES, MIN_VERTICES,
    )
except ImportError:
    from primary_oracle import (
        INVALID_RESULT, MAX_EDGES, MAX_PARSEABLE_INPUT_LENGTH,
        MAX_RESULT, MAX_VERTICES, MIN_VERTICES,
    )


def _validated_graph(values: Sequence[int] | None, input_is_null: bool,
                     input_length: int | None) -> tuple[int, list[list[int]]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, edge_count = values[0], values[1]
    if not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    adjacency = [[] for _ in range(n)]
    indegree = [0] * n
    seen: set[tuple[int, int]] = set()
    for i in range(edge_count):
        u, v = values[2 + 2 * i:4 + 2 * i]
        if not 0 <= u < n or not 0 <= v < n or u == v or (u, v) in seen:
            return None
        seen.add((u, v))
        adjacency[u].append(v)
        indegree[v] += 1
    for neighbors in adjacency:
        neighbors.sort()
    queue = deque(i for i, degree in enumerate(indegree) if degree == 0)
    visited = 0
    while queue:
        u = queue.popleft()
        visited += 1
        for v in adjacency[u]:
            indegree[v] -= 1
            if indegree[v] == 0:
                queue.append(v)
    return (n, adjacency) if visited == n else None


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _validated_graph(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, adjacency = parsed

    @lru_cache(maxsize=None)
    def suffix_optimum(left: int, used_right: int) -> int:
        if left == n:
            return 0
        best = suffix_optimum(left + 1, used_right)
        for right in adjacency[left]:
            bit = 1 << right
            if not used_right & bit:
                best = max(best, 1 + suffix_optimum(left + 1, used_right | bit))
        return best

    maximum = suffix_optimum(0, 0)
    successor = [n] * n
    used_right = 0
    fixed = 0
    for left in range(n):
        for right in (*adjacency[left], n):
            matched = right < n
            if matched and used_right & (1 << right):
                continue
            next_used = used_right | ((1 << right) if matched else 0)
            if fixed + int(matched) + suffix_optimum(left + 1, next_used) == maximum:
                successor[left] = right
                used_right = next_used
                fixed += int(matched)
                break
    path_count = n - maximum
    packed_successors = sum(next_vertex << (4 * vertex)
                            for vertex, next_vertex in enumerate(successor))
    result = (path_count << 40) | packed_successors
    return result if 0 <= result <= MAX_RESULT else INVALID_RESULT
