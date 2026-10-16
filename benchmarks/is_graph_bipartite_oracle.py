"""Independent bounded oracle for the pinned C++ BFS bipartite check."""

from __future__ import annotations

from collections import deque

MAX_VERTICES = 64
MAX_EDGES = 256
# Admit one edge-count-over-bound fixture with 257 endpoint pairs.
MAX_INPUT_LENGTH = 2 + 2 * (MAX_EDGES + 1)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return 1 for bipartite, 0 for not bipartite, or -1 for invalid input."""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT

    vertex_count, edge_count = values[:2]
    if (not 0 <= vertex_count <= MAX_VERTICES
            or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 2 * edge_count):
        return INVALID_RESULT

    adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
    for index in range(edge_count):
        u, v = values[2 + 2 * index:4 + 2 * index]
        if not 1 <= u <= vertex_count or not 1 <= v <= vertex_count:
            return INVALID_RESULT
        u -= 1
        v -= 1
        adjacency[u].append(v)
        adjacency[v].append(u)

    side = [-1] * vertex_count
    bipartite = True
    for start in range(vertex_count):
        if side[start] != -1:
            continue
        side[start] = 0
        queue = deque([start])
        while queue:
            current = queue.popleft()
            for neighbor in adjacency[current]:
                if side[neighbor] == -1:
                    side[neighbor] = 1 ^ side[current]
                    queue.append(neighbor)
                elif side[neighbor] == side[current]:
                    bipartite = False
    return int(bipartite)
