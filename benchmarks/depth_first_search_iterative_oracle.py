"""Independent breadth-first reachability oracle for the iterative DFS benchmark."""

from __future__ import annotations

from collections import deque

MAX_VERTICES = 64
MAX_EDGES = 256
MAX_INPUT_LENGTH = 4 + 2 * MAX_EDGES
I64_MIN, I64_MAX = -(2**63), 2**63 - 1

def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    vertex_count, edge_count, source, target = values[:4]
    if (not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or not 0 <= source < vertex_count
            or len(values) != 4 + 2 * edge_count):
        return -1
    adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
    for offset in range(4, len(values), 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < vertex_count or not 0 <= right < vertex_count:
            return -1
        adjacency[left].append(right)
        adjacency[right].append(left)
    seen = {source}
    pending = deque([source])
    while pending:
        current = pending.popleft()
        if current == target:
            return 1
        for neighbor in adjacency[current]:
            if neighbor not in seen:
                seen.add(neighbor)
                pending.append(neighbor)
    return 0
