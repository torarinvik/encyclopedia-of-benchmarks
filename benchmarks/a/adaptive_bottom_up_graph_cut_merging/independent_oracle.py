"""Independent exhaustive minimum-cut reference for the bounded graph profile."""

INVALID_RESULT = -1
MAX_VERTICES = 8
MAX_BOUNDARY_RECORDS = 16
MAX_BLOCKS = 4
MAX_CAPACITY = 7
MAX_PARSEABLE_INPUT_LENGTH = 92


def _decode(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63)
                   for x in values)):
        return None
    n, m, blocks_count = values[:3]
    if (n < 2 or n > MAX_VERTICES or m < 0 or m > MAX_BOUNDARY_RECORDS
            or blocks_count < 1 or blocks_count > min(n, MAX_BLOCKS)
            or len(values) != 3 + 3 * n + 4 * m):
        return None
    blocks = values[3:3 + n]
    if (any(b < 0 or b >= blocks_count for b in blocks)
            or set(blocks) != set(range(blocks_count))):
        return None
    source_caps = values[3 + n:3 + 2 * n]
    sink_caps = values[3 + 2 * n:3 + 3 * n]
    if any(c < 0 or c > MAX_CAPACITY for c in source_caps + sink_caps):
        return None
    arcs = []
    at = 3 + 3 * n
    for i in range(m):
        u, v, uv, vu = values[at + 4 * i:at + 4 * i + 4]
        if (u < 0 or u >= n or v < 0 or v >= n or u == v
                or uv < 0 or uv > MAX_CAPACITY or vu < 0 or vu > MAX_CAPACITY):
            return None
        arcs.append((u, v, uv, vu))
    return n, source_caps, sink_caps, arcs


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, source_caps, sink_caps, arcs = parsed
    best = None
    for mask in range(1 << n):
        cut = 0
        for u in range(n):
            in_source_side = bool(mask & (1 << u))
            if not in_source_side:
                cut += source_caps[u]
            if in_source_side:
                cut += sink_caps[u]
        for u, v, uv, vu in arcs:
            u_source = bool(mask & (1 << u))
            v_source = bool(mask & (1 << v))
            if u_source and not v_source:
                cut += uv
            if v_source and not u_source:
                cut += vu
        if best is None or cut < best:
            best = cut
    return best if best is not None else INVALID_RESULT
