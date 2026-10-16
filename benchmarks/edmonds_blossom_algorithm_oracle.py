"""Independent bounded oracle for Edmonds general-graph matching."""

from __future__ import annotations

from functools import lru_cache

MAX_VERTICES = 20
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2
            or any(type(value) is not int for value in values)):
        return -1
    n, m = values[:2]
    if not 0 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return -1
    adjacency = [0] * n
    seen: set[tuple[int, int]] = set()
    for i in range(m):
        u, v = values[2 + 2 * i:4 + 2 * i]
        if not (0 <= u < n and 0 <= v < n) or u == v:
            return -1
        edge = (min(u, v), max(u, v))
        if edge in seen:
            continue
        seen.add(edge)
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u

    @lru_cache(maxsize=None)
    def solve(mask: int) -> int:
        if mask == 0:
            return 0
        first_bit = mask & -mask
        u = first_bit.bit_length() - 1
        rest = mask ^ first_bit
        best = solve(rest)
        partners = adjacency[u] & rest
        while partners:
            bit = partners & -partners
            partners ^= bit
            best = max(best, 1 + solve(rest ^ bit))
        return best

    return solve((1 << n) - 1)
