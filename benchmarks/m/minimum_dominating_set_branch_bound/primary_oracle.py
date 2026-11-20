"""Exact branch-and-bound reference for minimum dominating set."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 1
MAX_VERTICES = 12
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


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
    if m > n * (n - 1) // 2:
        return None
    if input_length != 2 + 2 * m:
        return None
    adjacency = [0] * n
    for edge in range(m):
        u, v = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        u_bit, v_bit = 1 << u, 1 << v
        if adjacency[u] & v_bit:
            return None
        adjacency[u] |= v_bit
        adjacency[v] |= u_bit
    closed = tuple(adjacency[v] | (1 << v) for v in range(n))
    return n, closed


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, closed = parsed
    full = (1 << n) - 1

    covered = 0
    greedy_count = 0
    while covered != full:
        chosen = max(
            range(n),
            key=lambda vertex: ((closed[vertex] & ~covered).bit_count(), -vertex),
        )
        covered |= closed[chosen]
        greedy_count += 1

    def search(current: int, chosen_count: int, best: int) -> int:
        if chosen_count >= best:
            return best
        if current == full:
            return chosen_count
        uncovered = full & ~current
        uncovered_count = uncovered.bit_count()
        maximum_gain = max((closed[v] & uncovered).bit_count() for v in range(n))
        lower_bound = (uncovered_count + maximum_gain - 1) // maximum_gain
        if chosen_count + lower_bound >= best:
            return best

        branch_vertex = min(
            (v for v in range(n) if uncovered & (1 << v)),
            key=lambda v: (closed[v].bit_count(), v),
        )
        candidates = [v for v in range(n) if closed[branch_vertex] & (1 << v)]
        candidates.sort(key=lambda v: (-(closed[v] & uncovered).bit_count(), v))
        for vertex in candidates:
            best = search(current | closed[vertex], chosen_count + 1, best)
        return best

    return search(0, 0, greedy_count)
