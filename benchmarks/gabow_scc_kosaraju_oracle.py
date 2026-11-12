"""Independent two-pass Kosaraju verifier for the bounded Gabow SCC profile."""

MAX_VERTICES = 40
MAX_EDGES = 2047
MAX_INPUT_LENGTH = 4096
MAX_OUTPUT_BYTES = 81
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values, input_is_null, input_length):
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or type(input_is_null) is not bool or (input_is_null and len(values) != 0)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return None
    for value in values:
        if type(value) is not int or value < I64_MIN or value > I64_MAX:
            return None
    if input_is_null or len(values) < 2:
        return None
    n, m = int(values[0]), int(values[1])
    if n < 0 or n > MAX_VERTICES or m < 0 or m > MAX_EDGES:
        return None
    if len(values) != 2 + 2*m:
        return None
    forward = [set() for _ in range(n)]
    reverse = [set() for _ in range(n)]
    for edge in range(m):
        source, target = values[2+2*edge:4+2*edge]
        if source < 0 or source >= n or target < 0 or target >= n:
            return None
        forward[source].add(target)
        reverse[target].add(source)
    return forward, reverse


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return -1, b""
    graph = _parse(values, input_is_null, input_length)
    if graph is None:
        return -1, b""
    forward, reverse = graph
    n = len(forward)
    visited = [False] * n
    finish_order = []

    def finish_dfs(vertex):
        visited[vertex] = True
        for neighbor in sorted(forward[vertex]):
            if not visited[neighbor]:
                finish_dfs(neighbor)
        finish_order.append(vertex)

    for vertex in range(n):
        if not visited[vertex]:
            finish_dfs(vertex)
    visited = [False] * n
    components = []

    def collect_dfs(vertex, component):
        visited[vertex] = True
        component.append(vertex)
        for neighbor in sorted(reverse[vertex]):
            if not visited[neighbor]:
                collect_dfs(neighbor, component)

    for vertex in reversed(finish_order):
        if not visited[vertex]:
            component = []
            collect_dfs(vertex, component)
            components.append(component)
    normalized = sorted((sorted(component) for component in components),
                        key=lambda component: tuple(component))
    encoded = bytearray([len(normalized)])
    for component in normalized:
        encoded.append(len(component))
        encoded.extend(component)
    result = bytes(encoded)
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return -2, b""
    return len(result), result
