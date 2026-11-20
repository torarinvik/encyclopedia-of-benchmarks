"""Independent exhaustive minimum-cut oracle for bounded pseudoflow inputs."""

MAX_NODES = 8
MAX_ARCS = 24
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_ARCS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_CAPACITY = 100
MAX_RESULT = MAX_ARCS * MAX_CAPACITY


def expected_result(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1

    n, m, source_raw, sink_raw = values[:4]
    if not (2 <= n <= MAX_NODES and 0 <= m <= MAX_ARCS
            and 1 <= source_raw <= n and 1 <= sink_raw <= n
            and source_raw != sink_raw and len(values) == 4 + 3 * m):
        return -1

    source, sink = source_raw - 1, sink_raw - 1
    ordinary = [vertex for vertex in range(n) if vertex not in (source, sink)]
    position = {vertex: index for index, vertex in enumerate(ordinary)}
    src = [0] * len(ordinary)
    dst = [0] * len(ordinary)
    direct = 0
    internal = []
    for i in range(m):
        u0, v0, capacity = values[4 + 3*i:7 + 3*i]
        if not (1 <= u0 <= n and 1 <= v0 <= n and u0 != v0
                and 0 <= capacity <= MAX_CAPACITY):
            return -1
        u, v = u0 - 1, v0 - 1
        if u == source:
            if v == sink:
                direct += capacity
            else:
                src[position[v]] += capacity
        elif v == sink:
            dst[position[u]] += capacity
        elif v == source or u == sink:
            return -1
        else:
            internal.append((position[u], position[v], capacity))

    answer = None
    for subset in range(1 << len(ordinary)):
        total = direct
        for vertex in range(len(ordinary)):
            on_source_side = (subset >> vertex) & 1
            total += dst[vertex] if on_source_side else src[vertex]
        for u, v, capacity in internal:
            if (subset >> u) & 1 and not ((subset >> v) & 1):
                total += capacity
        if answer is None or total < answer:
            answer = total
    return answer if answer is not None and 0 <= answer <= MAX_RESULT else -1


def verify_candidate(values, candidate, input_is_null=False, input_length=None):
    """Check an implementation result against all source-side subsets."""
    return candidate == expected_result(values, input_is_null, input_length)
