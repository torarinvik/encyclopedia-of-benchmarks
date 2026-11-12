"""Primary reachability-based oracle for the bounded Gabow SCC benchmark."""

MAX_VERTICES = 40
MAX_EDGES = 2047
MAX_INPUT_LENGTH = 4096
MAX_OUTPUT_BYTES = 81
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _read_graph(values, input_is_null, input_length):
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or type(input_is_null) is not bool or (input_is_null and values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_is_null or len(values) < 2:
        return None
    n, m = values[:2]
    if not (0 <= n <= MAX_VERTICES and 0 <= m <= MAX_EDGES):
        return None
    if len(values) != 2 + 2*m:
        return None
    adjacency = [set() for _ in range(n)]
    for pos in range(2, len(values), 2):
        source, target = values[pos], values[pos + 1]
        if not (0 <= source < n and 0 <= target < n):
            return None
        adjacency[source].add(target)
    return n, adjacency


def _encode(components):
    normalized = sorted((sorted(component) for component in components),
                        key=lambda component: tuple(component))
    encoded = bytearray([len(normalized)])
    for component in normalized:
        encoded.append(len(component))
        encoded.extend(component)
    return bytes(encoded)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return -1, b""
    graph = _read_graph(values, input_is_null, input_length)
    if graph is None:
        return -1, b""
    n, adjacency = graph
    reachable = [[False] * n for _ in range(n)]
    for v in range(n):
        reachable[v][v] = True
        for w in adjacency[v]:
            reachable[v][w] = True
    for middle in range(n):
        for source in range(n):
            if reachable[source][middle]:
                for target in range(n):
                    if reachable[middle][target]:
                        reachable[source][target] = True
    assigned = [False] * n
    components = []
    for source in range(n):
        if assigned[source]:
            continue
        component = [v for v in range(n)
                     if not assigned[v] and reachable[source][v] and reachable[v][source]]
        for v in component:
            assigned[v] = True
        components.append(component)
    encoded = _encode(components)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
