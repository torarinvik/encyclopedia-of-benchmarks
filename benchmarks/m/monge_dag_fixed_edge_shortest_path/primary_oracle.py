"""Monotone-minima reference for exact-edge shortest paths in a Monge DAG."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_N * (MAX_N + 1) // 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_EDGE_WEIGHT = 1_000_000
MAX_WORKSPACE_BYTES = 16_384
INVALID_RESULT = -1
INF = 1 << 60


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, edge_count = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= edge_count <= n:
        return None
    if len(values) != 2 + n * (n + 1) // 2:
        return None
    cost = [[0] * (n + 1) for _ in range(n + 1)]
    offset = 2
    for u in range(n):
        for v in range(u + 1, n + 1):
            weight = values[offset]
            offset += 1
            if not 0 <= weight <= MAX_EDGE_WEIGHT:
                return None
            cost[u][v] = weight
    # Adjacent quadrangles characterize Monge order on the valid staircase.
    for u in range(n - 1):
        for v in range(u + 2, n):
            if cost[u][v] + cost[u + 1][v + 1] > cost[u][v + 1] + cost[u + 1][v]:
                return None
    return n, edge_count, tuple(tuple(row) for row in cost)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, edge_count, cost = parsed
    previous = [INF] * (n + 1)
    previous[0] = 0
    for layer in range(1, edge_count + 1):
        current = [INF] * (n + 1)

        def solve(row_begin: int, row_end: int, col_begin: int, col_end: int) -> None:
            if row_begin >= row_end:
                return
            row = (row_begin + row_end) // 2
            last_column = min(col_end, row)
            best_column = col_begin
            best_value = INF
            for column in range(col_begin, last_column):
                if previous[column] != INF:
                    candidate = previous[column] + cost[column][row]
                    if candidate < best_value:
                        best_value = candidate
                        best_column = column
            current[row] = best_value
            solve(row_begin, row, col_begin, best_column + 1)
            solve(row + 1, row_end, best_column, col_end)

        solve(layer, n + 1, layer - 1, n)
        previous = current
    return previous[n]
