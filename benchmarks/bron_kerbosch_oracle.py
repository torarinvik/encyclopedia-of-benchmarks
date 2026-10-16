"""Contract oracle for the bounded maximal-clique bitset encoding."""

from __future__ import annotations

MAX_VERTICES = 5
MAX_INPUT_LENGTH = 7  # five rows plus one malformed extra value


def _population_count(value: int) -> int:
    count = 0
    while value:
        count += value & 1
        value >>= 1
    return count


def expected_result(values: list[int]) -> int:
    """Encode all maximal cliques as bits indexed by their vertex masks."""
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    vertex_count = values[0]
    if not 0 <= vertex_count <= MAX_VERTICES or len(values) != vertex_count + 1:
        return -1
    vertex_mask = (1 << vertex_count) - 1
    if any(row < 0 or row & ~vertex_mask for row in values[1:]):
        return -1

    adjacency = [values[vertex + 1] & ~(1 << vertex) for vertex in range(vertex_count)]
    for left in range(vertex_count):
        for right in range(left + 1, vertex_count):
            if bool(adjacency[left] & (1 << right)) != bool(adjacency[right] & (1 << left)):
                return -1

    result = 0

    def visit(clique: int, possible: int, excluded: int) -> None:
        nonlocal result
        if possible == 0 and excluded == 0:
            result |= 1 << clique
            return

        pivot = -1
        greatest_degree = -1
        candidates_for_pivot = possible | excluded
        for vertex in range(vertex_count):
            if candidates_for_pivot & (1 << vertex):
                degree = _population_count(adjacency[vertex])
                if degree > greatest_degree:
                    pivot = vertex
                    greatest_degree = degree

        candidates = possible if pivot == -1 else possible & ~adjacency[pivot] & vertex_mask
        for vertex in range(vertex_count):
            bit = 1 << vertex
            if not candidates & bit:
                continue
            visit(clique | bit, possible & adjacency[vertex], excluded & adjacency[vertex])
            possible &= ~bit
            excluded |= bit

    visit(0, vertex_mask, 0)
    return result
