"""Direct per-query BFS oracle for the bounded contour-sum ABI."""

from __future__ import annotations

import struct

MAX_N = 64
MAX_Q = 128
MAX_ABS_VALUE = 1_000_000
MAX_VALID_INPUT_LENGTH = 3 * MAX_N + 4 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` using a fresh BFS for each distance query."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or len(values) < 2):
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return -1, b""

    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return -1, b""
    edge_start = 2 + n
    operation_start = 3 * n
    if len(values) < operation_start:
        return -1, b""

    current = list(values[2:edge_start])
    if any(not -MAX_ABS_VALUE <= value <= MAX_ABS_VALUE for value in current):
        return -1, b""
    graph = [[] for _ in range(n)]
    parent = list(range(n))
    size = [1] * n

    def find(vertex):
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    edge_cursor = edge_start
    for _ in range(n - 1):
        u, v = values[edge_cursor:edge_cursor + 2]
        edge_cursor += 2
        if not (0 <= u < n and 0 <= v < n) or u == v:
            return -1, b""
        root_u, root_v = find(u), find(v)
        if root_u == root_v:
            return -1, b""
        if size[root_u] < size[root_v]:
            root_u, root_v = root_v, root_u
        parent[root_v] = root_u
        size[root_u] += size[root_v]
        graph[u].append(v)
        graph[v].append(u)

    operations = []
    cursor = operation_start
    query_count = 0
    for _ in range(q):
        if cursor >= len(values):
            return -1, b""
        kind = values[cursor]
        cursor += 1
        if kind == 0:
            if cursor + 2 > len(values):
                return -1, b""
            vertex, delta = values[cursor:cursor + 2]
            cursor += 2
            if not 0 <= vertex < n or not -MAX_ABS_VALUE <= delta <= MAX_ABS_VALUE:
                return -1, b""
            operations.append((0, vertex, delta))
        elif kind == 1:
            if cursor + 3 > len(values):
                return -1, b""
            vertex, left, right = values[cursor:cursor + 3]
            cursor += 3
            if not (0 <= vertex < n and 0 <= left < right <= n):
                return -1, b""
            operations.append((1, vertex, left, right))
            query_count += 1
        else:
            return -1, b""
    if cursor != len(values):
        return -1, b""

    answers = []
    for operation in operations:
        if operation[0] == 0:
            _, vertex, delta = operation
            current[vertex] += delta
        else:
            _, start, left, right = operation
            distances = [-1] * n
            distances[start] = 0
            pending = [start]
            for vertex in pending:
                for neighbor in graph[vertex]:
                    if distances[neighbor] == -1:
                        distances[neighbor] = distances[vertex] + 1
                        pending.append(neighbor)
            answers.append(sum(current[v] for v in range(n)
                               if left <= distances[v] < right))

    required = 8 * query_count
    effective_capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if required > 0 and (output_is_null or effective_capacity < required):
        return -2, b""
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output
