"""Branch-and-bound oracle for the bounded exact maximum independent set profile."""

from __future__ import annotations

from typing import Sequence

MAX_N = 22
MAX_EDGES = MAX_N * (MAX_N - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_WORKSPACE_BYTES = 2048
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> list[int] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, edge_count = values[:2]
    if not 0 <= n <= MAX_N or not 0 <= edge_count <= n * (n - 1) // 2:
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    adjacency = [0] * n
    for index in range(edge_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if not (0 <= left < n and 0 <= right < n and left != right):
            return None
        left_bit, right_bit = 1 << left, 1 << right
        if adjacency[left] & right_bit:
            return None
        adjacency[left] |= right_bit
        adjacency[right] |= left_bit
    return adjacency


def _clique_cover_bound(adjacency: list[int], remaining: int) -> int:
    """Greedily partition the remaining graph into cliques."""
    cover_count = 0
    unassigned = remaining
    while unassigned:
        cover_count += 1
        candidates = unassigned
        while candidates:
            bit = candidates & -candidates
            vertex = bit.bit_length() - 1
            unassigned &= ~bit
            candidates &= ~bit
            candidates &= adjacency[vertex]
    return cover_count


def _solve(adjacency: list[int]) -> int:
    best = 0

    def search(remaining: int, chosen: int) -> None:
        nonlocal best
        if not remaining:
            best = max(best, chosen)
            return
        if chosen + remaining.bit_count() <= best:
            return
        if chosen + _clique_cover_bound(adjacency, remaining) <= best:
            return

        vertices = remaining
        branch_vertex = -1
        branch_degree = -1
        while vertices:
            bit = vertices & -vertices
            vertex = bit.bit_length() - 1
            degree = (adjacency[vertex] & remaining).bit_count()
            if degree > branch_degree:
                branch_vertex, branch_degree = vertex, degree
            vertices &= ~bit
        bit = 1 << branch_vertex
        search(remaining & ~bit & ~adjacency[branch_vertex], chosen + 1)
        search(remaining & ~bit, chosen)

    search((1 << len(adjacency)) - 1, 0)
    return best


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    adjacency = _parse(values, input_is_null, input_length)
    return INVALID_RESULT if adjacency is None else _solve(adjacency)
