"""Independent exhaustive directed minimum-cut oracle for EIBFS fixtures."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 2
MAX_VERTICES = 8
MAX_EDGES = 24
MAX_CAPACITY = 100
MAX_VALID_INPUT_LENGTH = 76
MAX_PARSEABLE_INPUT_LENGTH = 77


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return -1
    n, m, source, sink = values[:4]
    if (not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES
            or not 0 <= source < n or not 0 <= sink < n or source == sink
            or len(values) != 4 + 3 * m):
        return -1
    edges: list[tuple[int, int, int]] = []
    for offset in range(4, len(values), 3):
        u, v, capacity = values[offset:offset + 3]
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 0 <= capacity <= MAX_CAPACITY):
            return -1
        edges.append((u, v, capacity))
    best = MAX_EDGES * MAX_CAPACITY + 1
    for mask in range(1 << n):
        if not mask & (1 << source) or mask & (1 << sink):
            continue
        cut = sum(capacity for u, v, capacity in edges
                  if mask & (1 << u) and not mask & (1 << v))
        best = min(best, cut)
    return best
