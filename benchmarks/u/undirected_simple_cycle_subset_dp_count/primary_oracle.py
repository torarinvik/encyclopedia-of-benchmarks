"""Least-vertex subset-path DP for all undirected simple cycles."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 14
MAX_M = MAX_N * (MAX_N - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 2_097_152
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= n * (n - 1) // 2:
        return None
    if len(values) != 2 + 2 * m:
        return None
    adjacency = [[False] * n for _ in range(n)]
    previous: tuple[int, int] | None = None
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        edge = (u, v)
        if not 0 <= u < v < n or (previous is not None and edge <= previous):
            return None
        adjacency[u][v] = adjacency[v][u] = True
        previous = edge
    return n, adjacency


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, adjacency = parsed
    neighbors = [[v for v in range(n) if adjacency[u][v]] for u in range(n)]
    state_count = 1 << n
    dp = [[0] * n for _ in range(state_count)]
    for start in range(n):
        dp[1 << start][start] = 1

    oriented_cycles = 0
    for mask in range(1, state_count):
        start = (mask & -mask).bit_length() - 1
        cardinality = mask.bit_count()
        for endpoint in range(n):
            ways = dp[mask][endpoint]
            if ways == 0:
                continue
            if cardinality >= 3 and adjacency[endpoint][start]:
                oriented_cycles += ways
            for nxt in neighbors[endpoint]:
                if nxt > start and not (mask & (1 << nxt)):
                    dp[mask | (1 << nxt)][nxt] += ways
    return oriented_cycles // 2
