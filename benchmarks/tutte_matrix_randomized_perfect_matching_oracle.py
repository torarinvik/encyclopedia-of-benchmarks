"""Mucha--Sankowski Algorithm 2 over a supplied finite-field substitution."""

from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "tutte_matrix_randomized_perfect_matching"
FIELD_PRIME = 65_521
MAX_VERTICES = 8
MAX_N = MAX_VERTICES
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 + MAX_VERTICES)
WORKSPACE_BYTES = 8_192


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) < 2):
        return None
    n, edge_count = values[0], values[1]
    if (not 2 <= n <= MAX_VERTICES or n % 2 != 0
            or not 0 <= edge_count <= n * (n - 1) // 2
            or len(values) != 2 + 3 * edge_count):
        return None
    edges: list[tuple[int, int, int]] = []
    previous_pair = (-1, -1)
    for index in range(edge_count):
        u, v, substitution = values[2 + 3 * index:5 + 3 * index]
        if (not 0 <= u < v < n or (u, v) <= previous_pair
                or not 1 <= substitution < FIELD_PRIME):
            return None
        previous_pair = (u, v)
        edges.append((u, v, substitution))
    return n, edges


def _pow_mod(value: int, exponent: int) -> int:
    return pow(value % FIELD_PRIME, exponent, FIELD_PRIME)


def _invert(matrix: list[list[int]]) -> list[list[int]] | None:
    n = len(matrix)
    augmented = [
        [value % FIELD_PRIME for value in row]
        + [int(i == j) for j in range(n)]
        for i, row in enumerate(matrix)
    ]
    for column in range(n):
        pivot_row = next((row for row in range(column, n)
                          if augmented[row][column] != 0), None)
        if pivot_row is None:
            return None
        augmented[column], augmented[pivot_row] = augmented[pivot_row], augmented[column]
        inverse_pivot = _pow_mod(augmented[column][column], FIELD_PRIME - 2)
        augmented[column] = [value * inverse_pivot % FIELD_PRIME
                              for value in augmented[column]]
        for row in range(n):
            if row == column:
                continue
            factor = augmented[row][column]
            if factor:
                augmented[row] = [
                    (augmented[row][j] - factor * augmented[column][j]) % FIELD_PRIME
                    for j in range(2 * n)
                ]
    return [row[n:] for row in augmented]


def _eliminate(inverse: list[list[int]], row_active: list[bool],
               column_active: list[bool], pivot_row: int,
               pivot_column: int) -> bool:
    pivot = inverse[pivot_row][pivot_column]
    if pivot == 0:
        return False
    inverse_pivot = _pow_mod(pivot, FIELD_PRIME - 2)
    old = [row[:] for row in inverse]
    for row in range(len(inverse)):
        for column in range(len(inverse)):
            if (row_active[row] and row != pivot_row
                    and column_active[column] and column != pivot_column):
                correction = old[row][pivot_column] * old[pivot_row][column]
                inverse[row][column] = (
                    old[row][column] - correction * inverse_pivot
                ) % FIELD_PRIME
            else:
                inverse[row][column] = 0
    row_active[pivot_row] = False
    column_active[pivot_column] = False
    return True


def _construct(n: int, edges: list[tuple[int, int, int]]) -> list[int]:
    matrix = [[0] * n for _ in range(n)]
    for u, v, substitution in edges:
        matrix[u][v] = substitution
        matrix[v][u] = (-substitution) % FIELD_PRIME
    inverse = _invert(matrix)
    if inverse is None:
        return [0, 0]

    row_active = [True] * n
    column_active = [True] * n
    pairs: list[tuple[int, int]] = []
    for vertex in range(n):
        if not column_active[vertex]:
            continue
        partner = next((other for other in range(n)
                        if row_active[other] and other != vertex
                        and matrix[vertex][other] != 0
                        and inverse[other][vertex] != 0), None)
        if partner is None:
            return [0, 0]
        pairs.append((vertex, partner))
        if not _eliminate(inverse, row_active, column_active, partner, vertex):
            return [0, 0]
        if not _eliminate(inverse, row_active, column_active, vertex, partner):
            return [0, 0]

    result = [1, len(pairs)]
    for u, v in pairs:
        result.extend((u, v))
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    n, edges = parsed
    result = _construct(n, edges)
    payload = b"".join(struct.pack("<q", value) for value in result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
