"""Subset dynamic-programming reference for minimum directed feedback arc set."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 1
MAX_VERTICES = 8
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1)
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
INF = 1 << 60


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n, m = values[0], values[1]
    if not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if input_length != 2 + 2 * m:
        return None
    outgoing = [0] * n
    for edge in range(m):
        tail, head = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= tail < n or not 0 <= head < n or tail == head:
            return None
        bit = 1 << head
        if outgoing[tail] & bit:
            return None
        outgoing[tail] |= bit
    return n, tuple(outgoing)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, outgoing = parsed
    full = (1 << n) - 1
    dp = [INF] * (full + 1)
    dp[0] = 0
    for prefix in range(full + 1):
        if dp[prefix] == INF:
            continue
        for vertex in range(n):
            bit = 1 << vertex
            if prefix & bit:
                continue
            # Appending vertex last makes its arcs into the prefix backward.
            cost = (outgoing[vertex] & prefix).bit_count()
            target = prefix | bit
            candidate = dp[prefix] + cost
            if candidate < dp[target]:
                dp[target] = candidate
    return dp[full]
