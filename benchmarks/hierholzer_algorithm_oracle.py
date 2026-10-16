"""Independent scalar oracle for the pinned Java Hierholzer implementation."""

from __future__ import annotations

OFFSET = 14695981039346656037
PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
MAX_VERTICES = 8
MAX_EDGES = 256
MAX_INPUT = 2 + 2 * MAX_EDGES


def _hash_record(record: list[int]) -> int:
    digest = OFFSET
    for value in record:
        word = value & MASK64
        for shift in range(0, 64, 8):
            digest = ((digest ^ ((word >> shift) & 0xFF)) * PRIME) & MASK64
    return digest & MASK63


def _has_circuit(adjacency: list[list[int]]) -> bool:
    if not adjacency:
        return True
    if any(len(neighbors) % 2 for neighbors in adjacency):
        return False
    start = next((vertex for vertex, neighbors in enumerate(adjacency) if neighbors), None)
    if start is None:
        return True
    visited = {start}
    stack = [start]
    while stack:
        vertex = stack.pop()
        for neighbor in adjacency[vertex]:
            if neighbor not in visited:
                visited.add(neighbor)
                stack.append(neighbor)
    return all(not neighbors or vertex in visited for vertex, neighbors in enumerate(adjacency))


def _source_circuit(adjacency: list[list[int]]) -> list[int]:
    start = next((vertex for vertex, neighbors in enumerate(adjacency) if neighbors), None)
    if start is None:
        return [] if not adjacency else [0]
    remaining = [neighbors.copy() for neighbors in adjacency]
    path = [start]
    circuit: list[int] = []
    while path:
        vertex = path[-1]
        if remaining[vertex]:
            neighbor = remaining[vertex].pop(0)
            remaining[neighbor].remove(vertex)
            path.append(neighbor)
        else:
            circuit.insert(0, path.pop())
    return circuit


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2 or
            len(values) > MAX_INPUT or
            any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                for value in values)):
        return -1
    vertex_count, edge_count = values[:2]
    if not 0 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return -1
    if (vertex_count == 0 and edge_count != 0) or len(values) != 2 + 2 * edge_count:
        return -1
    adjacency = [[] for _ in range(vertex_count)]
    for index in range(edge_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= left < vertex_count or not 0 <= right < vertex_count:
            return -1
        adjacency[left].append(right)
        adjacency[right].append(left)
    valid = _has_circuit(adjacency)
    route = _source_circuit(adjacency) if valid else []
    return _hash_record([int(valid), len(route), *route])
