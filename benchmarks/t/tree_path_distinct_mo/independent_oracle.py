"""Endpoint-climbing reference for static tree-path color counts."""

import struct

MAX_N = 32
MAX_Q = 32
MAX_VALID_INPUT_LENGTH = 3 * MAX_N + 2 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 16384


def evaluate(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 3 * n + 2 * q:
        return -1, b""
    colors = values[2:2 + n]
    graph = [[] for _ in range(n)]
    components = list(range(n))

    def root(vertex):
        while components[vertex] != vertex:
            components[vertex] = components[components[vertex]]
            vertex = components[vertex]
        return vertex

    at = 2 + n
    for _ in range(n - 1):
        a, b = values[at], values[at + 1]
        at += 2
        if a < 0 or a >= n or b < 0 or b >= n or a == b:
            return -1, b""
        ra, rb = root(a), root(b)
        if ra == rb:
            return -1, b""
        components[rb] = ra
        graph[a].append(b)
        graph[b].append(a)
    edges = []
    for _ in range(q):
        a, b = values[at], values[at + 1]
        at += 2
        if a < 0 or a >= n or b < 0 or b >= n:
            return -1, b""
        edges.append((a, b))

    answers = []
    for a, b in edges:
        parent = [-1] * n
        depth = [0] * n
        parent[a] = a
        todo = [a]
        head = 0
        while head < len(todo):
            u = todo[head]
            head += 1
            for v in graph[u]:
                if parent[v] == -1:
                    parent[v] = u
                    depth[v] = depth[u] + 1
                    todo.append(v)
        seen = set()
        u, v = a, b
        while depth[u] > depth[v]:
            seen.add(colors[u])
            u = parent[u]
        while depth[v] > depth[u]:
            seen.add(colors[v])
            v = parent[v]
        while u != v:
            seen.add(colors[u])
            seen.add(colors[v])
            u, v = parent[u], parent[v]
        seen.add(colors[u])
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
    result, payload = evaluate(values)
    if result < 0:
        return result, payload
    if output_is_null or output_capacity is not None and output_capacity < result:
        return -2, b""
    return result, payload
