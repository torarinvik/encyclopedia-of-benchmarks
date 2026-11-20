"""Independent exhaustive directed-cut reference for bounded max-flow values."""

INVALID_RESULT = -1
MAX_VERTICES = 8
MAX_ARCS = 24
MAX_CAPACITY = 15
MAX_PARSEABLE_INPUT_LENGTH = 77


def _parse(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, source, sink = values[:4]
    if (not 2 <= n <= MAX_VERTICES or not 0 <= m <= MAX_ARCS
            or not 0 <= source < n or not 0 <= sink < n or source == sink
            or len(values) != 4 + 3 * m):
        return None
    arcs = []
    for index in range(m):
        u, v, capacity = values[4 + 3 * index:7 + 3 * index]
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 0 <= capacity <= MAX_CAPACITY):
            return None
        arcs.append((u, v, capacity))
    return n, source, sink, arcs


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, source, sink, arcs = parsed
    best = None
    for mask in range(1 << n):
        if not (mask & (1 << source)) or (mask & (1 << sink)):
            continue
        cut_capacity = sum(capacity for u, v, capacity in arcs
                           if mask & (1 << u) and not (mask & (1 << v)))
        if best is None or cut_capacity < best:
            best = cut_capacity
    return best if best is not None else INVALID_RESULT
