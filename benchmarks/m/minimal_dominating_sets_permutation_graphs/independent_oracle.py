"""Independent subset/private-neighbor oracle for permutation-graph counts."""

from __future__ import annotations

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 9
MAX_PARSEABLE_INPUT_LENGTH = 10
MAX_RESULT = 255
WORKSPACE_BYTES = 1_048_576


def _adjacency_masks(top: list[int]) -> list[int]:
    n = len(top)
    result = [1 << x for x in range(n)]
    for x in range(n):
        for y in range(x + 1, n):
            if top[x] > top[y]:
                result[x] |= 1 << y
                result[y] |= 1 << x
    return result


def _is_minimal_dominating(mask: int, adjacency: list[int], full: int) -> bool:
    covered = 0
    for vertex in range(len(adjacency)):
        if mask & (1 << vertex):
            covered |= adjacency[vertex]
    if covered != full:
        return False
    # Check the private-neighbor characterization directly: each selected
    # vertex needs a point in its closed neighborhood uncovered by the rest.
    for vertex in range(len(adjacency)):
        bit = 1 << vertex
        if mask & bit:
            other_coverage = 0
            for other in range(len(adjacency)):
                if other != vertex and mask & (1 << other):
                    other_coverage |= adjacency[other]
            if adjacency[vertex] & ~other_coverage == 0:
                return False
    return True


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if values is None or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 1:
        return -1
    top = list(values[1:])
    if any(rank < 0 or rank >= n for rank in top) or len(set(top)) != n:
        return -1
    adjacency = _adjacency_masks(top)
    full = (1 << n) - 1
    return sum(
        _is_minimal_dominating(mask, adjacency, full)
        for mask in range(1, 1 << n)
    )
