"""Independent oracle for the bounded directed check_cycle benchmark."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_VERTICES = 32
MAX_EDGES = 256
MAX_INPUT_LENGTH = 2 + 2 * (MAX_EDGES + 1)  # one extra edge for an invalid workload case


def expected_result(values: list[int]) -> int:
    """Return 1 for a directed cycle, 0 for a DAG, and -1 for malformed input."""
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    vertex_count, edge_count = values[:2]
    if not 0 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return -1
    if len(values) != 2 + 2 * edge_count:
        return -1

    indegree = [0] * vertex_count
    adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
    for offset in range(2, len(values), 2):
        origin, destination = values[offset:offset + 2]
        if not 0 <= origin < vertex_count or not 0 <= destination < vertex_count:
            return -1
        adjacency[origin].append(destination)
        indegree[destination] += 1

    ready = [vertex for vertex, degree in enumerate(indegree) if degree == 0]
    removed = 0
    while ready:
        vertex = ready.pop()
        removed += 1
        for destination in adjacency[vertex]:
            indegree[destination] -= 1
            if indegree[destination] == 0:
                ready.append(destination)
    return int(removed != vertex_count)
