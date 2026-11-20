"""Direct path-search reference for tree-path distinct-color queries."""

import struct

MAX_N = 32
MAX_Q = 32
MAX_VALID_INPUT_LENGTH = 3 * MAX_N + 2 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 16384


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or len(values) < 3
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    if len(values) != 3 * n + 2 * q:
        return None
    colors = values[2:2 + n]
    graph = [[] for _ in range(n)]
    parent = list(range(n))

    def find(vertex):
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    offset = 2 + n
    for _ in range(n - 1):
        u, v = values[offset:offset + 2]
        offset += 2
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        root_u, root_v = find(u), find(v)
        if root_u == root_v:
            return None
        parent[root_v] = root_u
        graph[u].append(v)
        graph[v].append(u)
    queries = []
    for _ in range(q):
        u, v = values[offset:offset + 2]
        offset += 2
        if not 0 <= u < n or not 0 <= v < n:
            return None
        queries.append((u, v))
    return n, colors, graph, queries


def evaluate(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, colors, graph, queries = parsed
    answers = []
    for source, target in queries:
        parent = [-1] * n
        parent[source] = source
        stack = [source]
        while stack:
            vertex = stack.pop()
            if vertex == target:
                break
            for neighbor in graph[vertex]:
                if parent[neighbor] == -1:
                    parent[neighbor] = vertex
                    stack.append(neighbor)
        seen = set()
        vertex = target
        while vertex != source:
            seen.add(colors[vertex])
            vertex = parent[vertex]
        seen.add(colors[source])
        answers.append(len(seen))
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
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
