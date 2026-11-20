"""Independent all-pairs vertex-deletion oracle for weighted two-cuts."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = 28
MAX_VALID_INPUT_LENGTH = 2 + MAX_VERTICES + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MODULUS = 998244353
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _connected(adjacency: list[list[bool]], n: int, removed: int) -> bool:
    start = 0
    while start == removed:
        start += 1
    seen = [False] * n
    seen[start] = True
    queue = [start]
    for vertex in queue:
        for other in range(n):
            if other != removed and adjacency[vertex][other] and not seen[other]:
                seen[other] = True
                queue.append(other)
    return sum(seen) == n - (removed >= 0)


def _component_count(adjacency: list[list[bool]], n: int, removed_u: int, removed_v: int) -> int:
    seen = [False] * n
    count = 0
    for start in range(n):
        if start in (removed_u, removed_v) or seen[start]:
            continue
        count += 1
        seen[start] = True
        queue = [start]
        for vertex in queue:
            for other in range(n):
                if other not in (removed_u, removed_v) and adjacency[vertex][other] and not seen[other]:
                    seen[other] = True
                    queue.append(other)
    return count


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Try every unordered pair and count components directly after deletion."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT
    if input_is_null:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    n, m = values[:2]
    if not 3 <= n <= MAX_VERTICES or not 3 <= m <= MAX_EDGES:
        return INVALID_RESULT
    if len(values) != 2 + n + 2 * m:
        return INVALID_RESULT
    weights = values[2:2 + n]
    if any(not 0 <= weight <= 1_000_000 for weight in weights):
        return INVALID_RESULT
    adjacency = [[False] * n for _ in range(n)]
    offset = 2 + n
    for edge_id in range(m):
        u, v = values[offset + 2 * edge_id:offset + 2 * edge_id + 2]
        if not 0 <= u < n or not 0 <= v < n or u == v or adjacency[u][v]:
            return INVALID_RESULT
        adjacency[u][v] = adjacency[v][u] = True
    if not all(_connected(adjacency, n, removed) for removed in range(-1, n)):
        return INVALID_RESULT
    total = 0
    for u in range(n):
        for v in range(u + 1, n):
            components = _component_count(adjacency, n, u, v)
            total = (total + weights[u] * weights[v] * max(0, components - 1)) % MODULUS
    return total
