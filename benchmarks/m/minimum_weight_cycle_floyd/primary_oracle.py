"""Incremental Floyd reference for minimum weighted undirected cycle."""

import struct

MAX_N = 9
MAX_EDGES = MAX_N * (MAX_N - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8
MAX_WORKSPACE_BYTES = 4096
INF = 1 << 60


def _parse(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return None
    n, m = values[:2]
    if not 3 <= n <= MAX_N or not 0 <= m <= n * (n - 1) // 2:
        return None
    if len(values) != 2 + 3 * m:
        return None

    edge = [[INF] * n for _ in range(n)]
    for i in range(n):
        edge[i][i] = 0
    for index in range(m):
        u, v, weight = values[2 + 3 * index:5 + 3 * index]
        if not 0 <= u < n or not 0 <= v < n or u == v or not 1 <= weight <= 1000:
            return None
        if edge[u][v] != INF:
            return None
        edge[u][v] = edge[v][u] = weight
    return n, edge


def evaluate(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, edge = parsed
    dist = [row[:] for row in edge]
    best = INF
    for k in range(n):
        # dist[i][j] currently uses only vertices numbered below k.
        for i in range(k):
            if edge[i][k] == INF:
                continue
            for j in range(i + 1, k):
                if edge[k][j] == INF or dist[i][j] == INF:
                    continue
                candidate = edge[i][k] + edge[k][j] + dist[i][j]
                if candidate < best:
                    best = candidate
        for i in range(n):
            if dist[i][k] == INF:
                continue
            for j in range(n):
                if dist[k][j] != INF:
                    candidate = dist[i][k] + dist[k][j]
                    if candidate < dist[i][j]:
                        dist[i][j] = candidate
    value = -1 if best == INF else best
    payload = struct.pack("<q", value)
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
