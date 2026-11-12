"""Independent target-wise verifier for the bounded gated graph update."""

import math

from graphai_ggnn_message_update_oracle import (
    MAX_EDGES, MAX_FEATURES, MAX_NODES, MAX_PARSEABLE_INPUT_LENGTH,
)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return -1, []
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and len(values) != 0)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return -1, []
    numbers = []
    for value in values:
        if type(value) not in (int, float):
            return -1, []
        try:
            value = float(value)
        except (OverflowError, ValueError):
            return -1, []
        if not math.isfinite(value):
            return -1, []
        numbers.append(value)
    if input_is_null or len(numbers) < 3:
        return -1, []
    head = numbers[0:3]
    if any(x != math.trunc(x) for x in head):
        return -1, []
    n, m, d = map(int, head)
    if not (1 <= n <= MAX_NODES and 0 <= m <= MAX_EDGES and 1 <= d <= MAX_FEATURES):
        return -1, []
    if len(numbers) != 4 + n + m + n*d + 6*n*n:
        return -1, []
    p = 3
    row_end = p + n + 1
    edge_end = row_end + m
    state_end = edge_end + n*d
    mat_end = state_end + 6*n*n
    rows_raw = numbers[p:row_end]
    edges_raw = numbers[row_end:edge_end]
    if (rows_raw[0] != 0 or rows_raw[-1] != m
            or any(x != math.trunc(x) or x < 0 or x > m for x in rows_raw)
            or any(a > b for a, b in zip(rows_raw, rows_raw[1:]))
            or any(x != math.trunc(x) or x < 0 or x >= n for x in edges_raw)):
        return -1, []
    state = numbers[edge_end:state_end]
    matrices = numbers[state_end:mat_end]
    if any(abs(x) > 1.0 for x in state) or any(abs(x) > 0.25 for x in matrices):
        return -1, []
    count = n*d
    if output_is_null or (output_capacity is not None and output_capacity < count):
        return -2, []

    adjacency = []
    for vertex in range(n):
        adjacency.append([int(x) for x in edges_raw[int(rows_raw[vertex]):int(rows_raw[vertex+1])]])
    h = [state[v*d:(v+1)*d] for v in range(n)]
    aggregate = [
        [math.fsum(h[neighbor][f] for neighbor in adjacency[v]) for f in range(d)]
        for v in range(n)
    ]
    block = n*n
    wz, wr, wc = matrices[0:block], matrices[block:2*block], matrices[2*block:3*block]
    uz, ur, uc = matrices[3*block:4*block], matrices[4*block:5*block], matrices[5*block:6*block]

    def gate(matrix_w, matrix_u, vertex, feature):
        left = math.fsum(matrix_w[vertex*n+k] * aggregate[k][feature] for k in range(n))
        right = math.fsum(matrix_u[vertex*n+k] * h[k][feature] for k in range(n))
        return 1.0 / (1.0 + math.exp(-(left + right)))

    update = [[gate(wz, uz, v, f) for f in range(d)] for v in range(n)]
    reset = [[gate(wr, ur, v, f) for f in range(d)] for v in range(n)]
    output = []
    for v in range(n):
        for f in range(d):
            graph_term = math.fsum(wc[v*n+k] * aggregate[k][f] for k in range(n))
            state_term = math.fsum(uc[v*n+k] * reset[k][f] * h[k][f] for k in range(n))
            proposal = math.tanh(graph_term + state_term)
            output.append((1.0-update[v][f])*h[v][f] + update[v][f]*proposal)
    return count, output
