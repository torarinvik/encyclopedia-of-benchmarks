"""Two-pass recurrence reference for edge-directed tree hitting costs."""

import struct

MAX_N = 16
MAX_INPUT_LENGTH = 2 + 3 * (MAX_N - 1) + 1
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH - 1
MAX_OUTPUT_BYTES = 2 * (MAX_N - 1) * 8
MAX_WORKSPACE_BYTES = 16384


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_INPUT_LENGTH or input_length != len(values)
            or len(values) < 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, root = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= root < n:
        return None
    if len(values) != 2 + 3 * (n - 1):
        return None
    graph = [[] for _ in range(n)]
    edges = []
    dsu = list(range(n))

    def find(vertex):
        while dsu[vertex] != vertex:
            dsu[vertex] = dsu[dsu[vertex]]
            vertex = dsu[vertex]
        return vertex

    offset = 2
    for _ in range(n - 1):
        u, v, weight = values[offset:offset + 3]
        offset += 3
        if not 0 <= u < n or not 0 <= v < n or u == v or not 1 <= weight <= 9:
            return None
        ru, rv = find(u), find(v)
        if ru == rv:
            return None
        dsu[rv] = ru
        graph[u].append((v, weight))
        graph[v].append((u, weight))
        edges.append((u, v, weight))
    return n, root, graph, edges


def evaluate(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, root, graph, edges = parsed
    parent = [-1] * n
    parent_weight = [0] * n
    order = [root]
    parent[root] = root
    for vertex in order:
        for neighbor, weight in graph[vertex]:
            if parent[neighbor] == -1:
                parent[neighbor] = vertex
                parent_weight[neighbor] = weight
                order.append(neighbor)

    down = [0] * n
    for vertex in reversed(order):
        down[vertex] = sum(weight for _, weight in graph[vertex])
        down[vertex] += sum(down[child] for child, _ in graph[vertex]
                            if parent[child] == vertex)
    up = [0] * n
    for vertex in order:
        for child, _ in graph[vertex]:
            if parent[child] == vertex:
                up[child] = up[vertex] + down[vertex] - down[child]

    answers = []
    for u, v, _weight in edges:
        if parent[u] == v:
            answers.extend((down[u], up[u]))
        else:
            answers.extend((up[v], down[v]))
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    try:
        actual_length = len(values)
    except TypeError:
        return -1, b""
    if input_length is not None and input_length != actual_length:
        return -1, b""
    result, payload = evaluate(values, False, actual_length)
    if result < 0:
        return result, payload
    if output_is_null or output_capacity is not None and output_capacity < result:
        return -2, b""
    return result, payload
