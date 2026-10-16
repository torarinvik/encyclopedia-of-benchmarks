"""Independent union-find oracle for bounded undirected-cycle inputs."""

from __future__ import annotations

INVALID_RESULT = -1
MAX_VERTICES = 32
MAX_EDGES = 256
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    vertex_count, edge_count = values[:2]
    if (not 0 <= vertex_count <= MAX_VERTICES
            or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 2 * edge_count):
        return INVALID_RESULT

    seen_edges: set[tuple[int, int]] = set()
    edges: list[tuple[int, int]] = []

    for offset in range(2, len(values), 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < vertex_count or not 0 <= right < vertex_count:
            return INVALID_RESULT
        edge = (min(left, right), max(left, right))
        if edge in seen_edges:
            return INVALID_RESULT
        seen_edges.add(edge)
        edges.append((left, right))

    parent = list(range(vertex_count))
    size = [1] * vertex_count

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    for left, right in edges:
        left_root, right_root = find(left), find(right)
        if left_root == right_root:
            return 1
        if size[left_root] < size[right_root]:
            left_root, right_root = right_root, left_root
        parent[right_root] = left_root
        size[left_root] += size[right_root]
    return 0
