"""Recursive adjacency squaring and distance recovery for Seidel APSP."""

import struct

MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 512
WORKSPACE_BYTES = 512


def _distances(adjacency):
    n = len(adjacency)
    if all(i == j or adjacency[i][j] for i in range(n) for j in range(n)):
        return [[int(i != j) for j in range(n)] for i in range(n)]
    squared = [[sum(adjacency[i][k] * adjacency[k][j] for k in range(n))
                for j in range(n)] for i in range(n)]
    expanded = [[int(i != j and (adjacency[i][j] or squared[i][j]))
                 for j in range(n)] for i in range(n)]
    coarse = _distances(expanded)
    degree = [sum(row) for row in adjacency]
    result = [[0] * n for _ in range(n)]
    for i in range(n):
        for j in range(n):
            if i != j:
                neighbor_sum = sum(coarse[i][k] * adjacency[k][j] for k in range(n))
                result[i][j] = 2 * coarse[i][j] - int(neighbor_sum < coarse[i][j] * degree[j])
    return result


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 8 or len(values) != 1 + n * n:
        return -1, b""
    matrix = [values[1 + i * n:1 + (i + 1) * n] for i in range(n)]
    if (any(value not in (0, 1) for row in matrix for value in row)
            or any(matrix[i][i] != 0 for i in range(n))
            or any(matrix[i][j] != matrix[j][i] for i in range(n) for j in range(i))):
        return -1, b""
    reached = 1
    while True:
        expanded = reached
        for i in range(n):
            if reached & (1 << i):
                for j in range(n):
                    if matrix[i][j]:
                        expanded |= 1 << j
        if expanded == reached:
            break
        reached = expanded
    if reached != (1 << n) - 1:
        return -1, b""
    required = 8 * n * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < required)):
        return -2, b""
    return required, b"".join(struct.pack("<q", value) for row in _distances(matrix) for value in row)
