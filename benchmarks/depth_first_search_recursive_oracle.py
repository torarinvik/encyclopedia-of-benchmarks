"""Independent BFS oracle for recursive DFS reachability in an undirected graph."""

from __future__ import annotations

from collections import deque

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_VERTICES = 64
MAX_EDGES = 256
MAX_INPUT_LENGTH = 518
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return 1 when target is reachable, 0 when absent, or -1 for malformed input."""
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    vertex_count, edge_count, source, target = values[:4]
    if (not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or not 0 <= source < vertex_count or len(values) != 4 + 2 * edge_count):
        return INVALID_RESULT
    adjacency = [[] for _ in range(vertex_count)]
    for edge in range(edge_count):
        left, right = values[4 + 2 * edge:6 + 2 * edge]
        if not 0 <= left < vertex_count or not 0 <= right < vertex_count:
            return INVALID_RESULT
        if right not in adjacency[left]:
            adjacency[left].append(right)
        if left not in adjacency[right]:
            adjacency[right].append(left)
    visited = {source}
    pending = deque([source])
    while pending:
        current = pending.popleft()
        if current == target:
            return 1
        for neighbor in adjacency[current]:
            if neighbor not in visited:
                visited.add(neighbor)
                pending.append(neighbor)
    return 0
