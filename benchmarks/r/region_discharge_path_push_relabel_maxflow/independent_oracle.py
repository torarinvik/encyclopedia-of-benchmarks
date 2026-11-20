"""Independent exhaustive minimum-cut reference for the bounded network."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_ARCS = 12
MAX_REGIONS = 4
MAX_CAPACITY = 7
MAX_PARSEABLE_INPUT_LENGTH = 50


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return None
    n, m, k, source, sink = values[:5]
    if (not 4 <= n <= MAX_VERTICES or not 1 <= m <= MAX_ARCS
            or not 2 <= k <= min(MAX_REGIONS, n - 2)
            or not 0 <= source < n or not 0 <= sink < n or source == sink
            or len(values) != 5 + n + 3 * m):
        return None
    regions = values[5:5 + n]
    for v, region in enumerate(regions):
        if v in (source, sink):
            if region != -1:
                return None
        elif not 0 <= region < k:
            return None
    if set(regions[v] for v in range(n) if v not in (source, sink)) != set(range(k)):
        return None
    arcs = []
    for i in range(m):
        u, v, cap = values[5 + n + 3 * i:8 + n + 3 * i]
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or v == source or u == sink or not 0 <= cap <= MAX_CAPACITY):
            return None
        arcs.append((u, v, cap))
    if not any(cap and regions[u] >= 0 and regions[v] >= 0 and regions[u] != regions[v]
               for u, v, cap in arcs):
        return None
    return n, source, sink, arcs


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, source, sink, arcs = parsed
    internal = [v for v in range(n) if v not in (source, sink)]
    best = None
    for mask in range(1 << len(internal)):
        source_side = {source}
        source_side.update(v for i, v in enumerate(internal) if mask & (1 << i))
        if sink in source_side:
            continue
        cut = sum(cap for u, v, cap in arcs if u in source_side and v not in source_side)
        if best is None or cut < best:
            best = cut
    return -1 if best is None else best

