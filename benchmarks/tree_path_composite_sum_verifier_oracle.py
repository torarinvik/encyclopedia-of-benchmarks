"""Independent affine-composition traversal for all rooted tree paths."""

import struct

from tree_path_composite_sum_oracle import (
    MAX_INPUT_LENGTH, MAX_N, MAX_OUTPUT_BYTES, MOD,
)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (input_length != len(values) or not 2 <= input_length <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + n + 4 * (n - 1):
        return -1, b""
    vertex_values = values[1:1 + n]
    if any(not 0 <= value < MOD for value in vertex_values):
        return -1, b""
    graph = [[] for _ in range(n)]
    dsu = list(range(n))

    def root_of(vertex):
        while dsu[vertex] != vertex:
            dsu[vertex] = dsu[dsu[vertex]]
            vertex = dsu[vertex]
        return vertex

    offset = 1 + n
    for edge_id in range(n - 1):
        u, v, multiplier, addend = values[offset:offset + 4]
        offset += 4
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 1 <= multiplier < MOD or not 0 <= addend < MOD):
            return -1, b""
        ru, rv = root_of(u), root_of(v)
        if ru == rv:
            return -1, b""
        dsu[rv] = ru
        graph[u].append((v, multiplier, addend))
        graph[v].append((u, multiplier, addend))

    answers = []
    for start in range(n):
        parent = [-1] * n
        coefficient = [0] * n
        constant = [0] * n
        parent[start] = start
        coefficient[start] = 1
        stack = [start]
        total = 0
        while stack:
            vertex = stack.pop()
            total = (total + coefficient[vertex] * vertex_values[vertex]
                     + constant[vertex]) % MOD
            for neighbor, multiplier, addend in graph[vertex]:
                if neighbor == parent[vertex]:
                    continue
                parent[neighbor] = vertex
                # The new edge transform is applied before the transforms closer
                # to start: F_child = F_parent composed with f_edge.
                coefficient[neighbor] = coefficient[vertex] * multiplier % MOD
                constant[neighbor] = (
                    coefficient[vertex] * addend + constant[vertex]) % MOD
                stack.append(neighbor)
        answers.append(total)
    payload = b"".join(struct.pack("<q", value) for value in answers)
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
