"""Independent exhaustive-cut reference for the bounded PEIBFS workload."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 6
MAX_BOUNDARY_RECORDS = 6
MAX_BLOCKS = 4
MAX_CAPACITY = 7
MAX_PARSEABLE_INPUT_LENGTH = 46


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n, m, block_count = values[:3]
    if (not 2 <= n <= MAX_VERTICES or not 0 <= m <= MAX_BOUNDARY_RECORDS
            or not 1 <= block_count <= min(n, MAX_BLOCKS)
            or len(values) != 3 + 3 * n + 4 * m):
        return None
    block_ids = values[3:3 + n]
    if any(not 0 <= b < block_count for b in block_ids) or set(block_ids) != set(range(block_count)):
        return None
    source_caps = values[3 + n:3 + 2 * n]
    sink_caps = values[3 + 2 * n:3 + 3 * n]
    if any(not 0 <= c <= MAX_CAPACITY for c in source_caps + sink_caps):
        return None
    edges = []
    offset = 3 + 3 * n
    for i in range(m):
        u, v, uv, vu = values[offset + 4 * i:offset + 4 * i + 4]
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 0 <= uv <= MAX_CAPACITY or not 0 <= vu <= MAX_CAPACITY):
            return None
        edges.append((u, v, uv, vu))
    return n, source_caps, sink_caps, edges


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, source_caps, sink_caps, edges = parsed
    best = None
    for mask in range(1 << n):
        cut = 0
        for u in range(n):
            source_side = bool(mask & (1 << u))
            cut += sink_caps[u] if source_side else source_caps[u]
        for u, v, uv, vu in edges:
            u_source = bool(mask & (1 << u))
            v_source = bool(mask & (1 << v))
            if u_source and not v_source:
                cut += uv
            elif v_source and not u_source:
                cut += vu
        if best is None or cut < best:
            best = cut
    return -1 if best is None else best
