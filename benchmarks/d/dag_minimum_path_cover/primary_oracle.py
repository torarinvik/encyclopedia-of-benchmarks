"""Kuhn-DFS reference for a canonical minimum path cover of a DAG."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MIN_VERTICES = 1
MAX_VERTICES = 10
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = (10 << 40) | ((1 << 40) - 1)
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[list[int]]] | None:
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
    adjacency = [[] for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    indegree = [0] * n
    for index in range(m):
        u, v = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= u < n or not 0 <= v < n or u == v or (u, v) in seen:
            return None
        seen.add((u, v))
        adjacency[u].append(v)
        indegree[v] += 1
    for neighbors in adjacency:
        neighbors.sort()
    queue = deque(vertex for vertex, degree in enumerate(indegree) if degree == 0)
    removed = 0
    while queue:
        u = queue.popleft()
        removed += 1
        for v in adjacency[u]:
            indegree[v] -= 1
            if indegree[v] == 0:
                queue.append(v)
    if removed != n:
        return None
    return n, adjacency


def _maximum_matching_size(adjacency: list[list[int]], n: int,
                           first_left: int, used_right: int) -> int:
    """Deterministic augmenting paths on remaining left and right copies."""
    pair_right = [-1] * n
    def augment(left: int, seen: list[bool]) -> bool:
        for right in adjacency[left]:
            if used_right & (1 << right) or seen[right]:
                continue
            seen[right] = True
            mate = pair_right[right]
            if mate < 0 or augment(mate, seen):
                pair_right[right] = left
                return True
        return False

    size = 0
    for left in range(first_left, n):
        if augment(left, [False] * n):
            size += 1
    return size


def _canonical_successors(adjacency: list[list[int]], n: int) -> tuple[int, list[int]]:
    maximum = _maximum_matching_size(adjacency, n, 0, 0)
    successor = [n] * n
    used_right = 0
    fixed = 0
    for left in range(n):
        for right in (*adjacency[left], n):
            matched = right < n
            if matched and used_right & (1 << right):
                continue
            next_used = used_right | ((1 << right) if matched else 0)
            attainable = fixed + int(matched) + _maximum_matching_size(
                adjacency, n, left + 1, next_used)
            if attainable == maximum:
                successor[left] = right
                used_right = next_used
                fixed += int(matched)
                break
    return maximum, successor


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, adjacency = parsed
    matching_size, successor = _canonical_successors(adjacency, n)
    path_count = n - matching_size
    packed_successors = sum(next_vertex << (4 * vertex)
                            for vertex, next_vertex in enumerate(successor))
    return (path_count << 40) | packed_successors
