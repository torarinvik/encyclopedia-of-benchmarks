"""Direct predecessor-scan reference for exact-edge Monge-DAG paths."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INF, INVALID_RESULT, MAX_EDGE_WEIGHT, MAX_N, MAX_PARSEABLE_INPUT_LENGTH,
)


def _decode(values: Sequence[int] | None, input_is_null: bool,
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
    weights = [[0] * (n + 1) for _ in range(n + 1)]
    offset = 2
    for u in range(n):
        for v in range(u + 1, n + 1):
            value = values[offset]
            offset += 1
            if not 0 <= value <= MAX_EDGE_WEIGHT:
                return None
            weights[u][v] = value
    for u in range(n - 1):
        for v in range(u + 2, n):
            if weights[u][v] + weights[u + 1][v + 1] > weights[u][v + 1] + weights[u + 1][v]:
                return None
    return n, edge_count, weights


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, edge_count, weights = parsed
    previous = [INF] * (n + 1)
    previous[0] = 0
    for layer in range(1, edge_count + 1):
        current = [INF] * (n + 1)
        for target in range(layer, n + 1):
            for source in range(layer - 1, target):
                if previous[source] != INF:
                    candidate = previous[source] + weights[source][target]
                    if candidate < current[target]:
                        current[target] = candidate
        previous = current
    return previous[n]
