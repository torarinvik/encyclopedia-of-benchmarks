"""Ordered branch-and-bound reference for the bounded maximum-clique profile."""

from __future__ import annotations

from typing import Sequence

MAX_VERTICES = 24
MAX_N = MAX_VERTICES
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 1 + MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_WORKSPACE_BYTES = 16384
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> list[int] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None

    vertex_count = values[0]
    if not 0 <= vertex_count <= MAX_VERTICES or len(values) != 1 + vertex_count:
        return None
    masks = list(values[1:])
    domain_mask = (1 << vertex_count) - 1
    if any(mask < 0 or mask & ~domain_mask for mask in masks):
        return None
    for vertex, mask in enumerate(masks):
        if mask & (1 << vertex):
            return None
    for left in range(vertex_count):
        for right in range(left + 1, vertex_count):
            if bool(masks[left] & (1 << right)) != bool(masks[right] & (1 << left)):
                return None
    return masks


def _solve(adjacency: list[int]) -> int:
    """Mirror the ordered DFS, including both suffix-safe pruning rules."""
    n = len(adjacency)
    best = 0
    suffix_best = [0] * n

    def search(candidates: int, chosen: int) -> bool:
        nonlocal best
        if candidates == 0:
            if chosen > best:
                best = chosen
                return True
            return False

        remaining = candidates
        while remaining:
            # Candidates are visited in ascending vertex order. This count is
            # the largest extension available from this position onward.
            if chosen + remaining.bit_count() <= best:
                return False
            bit = remaining & -remaining
            vertex = bit.bit_length() - 1
            remaining &= ~bit
            # suffix_best[v] is the optimum already obtained using vertices
            # with IDs at least v; it is an upper bound after this prefix.
            if chosen + suffix_best[vertex] <= best:
                return False
            if search(remaining & adjacency[vertex], chosen + 1):
                return True
        return False

    for root in range(n - 1, -1, -1):
        greater_vertices = ((1 << n) - 1) & ~((1 << (root + 1)) - 1)
        search(adjacency[root] & greater_vertices, 1)
        suffix_best[root] = best
    return best


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    adjacency = _parse(values, input_is_null, input_length)
    return INVALID_RESULT if adjacency is None else _solve(adjacency)
