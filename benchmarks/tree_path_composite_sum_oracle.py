"""Direct path-reconstruction oracle for rerooted affine path sums."""

import struct

MOD = 998_244_353
MAX_N = 32
MAX_VALID_INPUT_LENGTH = 5 * MAX_N - 3
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_N
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or len(values) < 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + n + 4 * (n - 1):
        return None
    vertex_values = values[1:1 + n]
    if any(not 0 <= value < MOD for value in vertex_values):
        return None
    graph = [[] for _ in range(n)]
    parent = list(range(n))

    def find(vertex):
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    edges = []
    offset = 1 + n
    for edge_id in range(n - 1):
        u, v, multiplier, addend = values[offset:offset + 4]
        offset += 4
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 1 <= multiplier < MOD or not 0 <= addend < MOD):
            return None
        root_u, root_v = find(u), find(v)
        if root_u == root_v:
            return None
        parent[root_v] = root_u
        edges.append((u, v, multiplier, addend))
        graph[u].append((v, edge_id))
        graph[v].append((u, edge_id))
    return n, vertex_values, graph, edges


def evaluate(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, vertex_values, graph, edges = parsed
    answers = []
    for root in range(n):
        parent = [-1] * n
        parent_edge = [-1] * n
        parent[root] = root
        stack = [root]
        while stack:
            vertex = stack.pop()
            for neighbor, edge_id in graph[vertex]:
                if neighbor == parent[vertex]:
                    continue
                parent[neighbor] = vertex
                parent_edge[neighbor] = edge_id
                stack.append(neighbor)
        total = 0
        for target in range(n):
            value = vertex_values[target]
            vertex = target
            while vertex != root:
                _u, _v, multiplier, addend = edges[parent_edge[vertex]]
                value = (multiplier * value + addend) % MOD
                vertex = parent[vertex]
            total = (total + value) % MOD
        answers.append(total)
    payload = b"".join(struct.pack("<q", value) for value in answers)
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
