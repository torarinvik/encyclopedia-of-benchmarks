"""Independent all-pairs-distance checker for contour-sum workloads."""

from __future__ import annotations

from collections import deque
import struct

MAX_N = 64
MAX_Q = 128
MAX_ABS_VALUE = 1_000_000
MAX_OUTPUT_BYTES = 8 * MAX_Q


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return the ABI result and bytes using precomputed BFS distance rows."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > 3 * MAX_N + 4 * MAX_Q + 1
            or input_length != len(values) or len(values) < 2):
        return -1, b""
    if any(type(item) is not int or not -(1 << 63) <= item < (1 << 63)
           for item in values):
        return -1, b""

    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return -1, b""
    edge_start = 2 + n
    operation_start = 3 * n
    if len(values) < operation_start:
        return -1, b""
    weights = list(values[2:edge_start])
    if any(not -MAX_ABS_VALUE <= x <= MAX_ABS_VALUE for x in weights):
        return -1, b""

    graph = [[] for _ in range(n)]
    edges = set()
    for i in range(n - 1):
        u, v = values[edge_start + 2 * i:edge_start + 2 * i + 2]
        if not (0 <= u < n and 0 <= v < n) or u == v:
            return -1, b""
        edge = (min(u, v), max(u, v))
        if edge in edges:
            return -1, b""
        edges.add(edge)
        graph[u].append(v)
        graph[v].append(u)

    distances = []
    for source in range(n):
        row = [-1] * n
        row[source] = 0
        queue = deque([source])
        while queue:
            u = queue.popleft()
            for v in graph[u]:
                if row[v] == -1:
                    row[v] = row[u] + 1
                    queue.append(v)
        if any(distance < 0 for distance in row):
            return -1, b""
        distances.append(row)

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
            if not (0 <= vertex < n and -MAX_ABS_VALUE <= delta <= MAX_ABS_VALUE):
                return -1, b""
            operations.append((kind, vertex, delta))
        elif kind == 1:
            if cursor + 3 > len(values):
                return -1, b""
            vertex, left, right = values[cursor:cursor + 3]
            cursor += 3
            if not (0 <= vertex < n and 0 <= left < right <= n):
                return -1, b""
            operations.append((kind, vertex, left, right))
            query_count += 1
        else:
            return -1, b""
    if cursor != len(values):
        return -1, b""

    answers = []
    for operation in operations:
        if operation[0] == 0:
            _, vertex, delta = operation
            weights[vertex] += delta
        else:
            _, source, left, right = operation
            answers.append(sum(weights[v] for v in range(n)
                               if left <= distances[source][v] < right))

    required = 8 * query_count
    cap = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if type(output_is_null) is not bool or type(cap) is not int or cap < 0:
        return -2, b""
    if required and (output_is_null or cap < required):
        return -2, b""
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload


def verify_result(values, result, output, **abi_options):
    """Compare a port's result/output pair with the independent distance table."""
    return (result, output) == expected_output(values, **abi_options)
