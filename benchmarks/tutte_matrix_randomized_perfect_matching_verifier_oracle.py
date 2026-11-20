"""Independent determinant/cofactor reference for the Tutte-matrix profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

FIELD_PRIME = 65_521
MAX_VERTICES = 8
MAX_N = MAX_VERTICES
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 + MAX_VERTICES)
WORKSPACE_BYTES = 8_192


def _valid_frame(values: Sequence[int] | None, length: int | None,
                 is_null: bool) -> tuple[int, list[tuple[int, int, int]]] | None:
    if (type(is_null) is not bool or is_null or type(values) not in (list, tuple)
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63)
                   for x in values)):
        return None
    actual_length = len(values) if length is None else length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    count_vertices, count_edges = values[0], values[1]
    if (count_vertices not in (2, 4, 6, 8)
            or count_edges < 0 or count_edges > count_vertices * (count_vertices - 1) // 2
            or actual_length != 2 + 3 * count_edges):
        return None
    edges = []
    prior_u = -1
    prior_v = -1
    for offset in range(2, actual_length, 3):
        u, v, value = values[offset:offset + 3]
        if (u < 0 or v <= u or v >= count_vertices
                or (u, v) <= (prior_u, prior_v)
                or value <= 0 or value >= FIELD_PRIME):
            return None
        prior_u, prior_v = u, v
        edges.append((u, v, value))
    return count_vertices, edges


def _determinant(matrix: list[list[int]]) -> int:
    """Leibniz expansion by first row, independent of Gaussian elimination."""
    n = len(matrix)
    if n == 0:
        return 1
    total = 0
    for column in range(n):
        value = matrix[0][column]
        if value == 0:
            continue
        minor = [row[:column] + row[column + 1:] for row in matrix[1:]]
        term = value * _determinant(minor)
        total += term if column % 2 == 0 else -term
    return total % FIELD_PRIME


def _principal_matrix(matrix: list[list[int]], vertices: list[int]) -> list[list[int]]:
    return [[matrix[u][v] for v in vertices] for u in vertices]


def _cofactor_matching(matrix: list[list[int]], vertices: list[int]) -> list[int]:
    pairs: list[tuple[int, int]] = []
    remaining = vertices[:]
    while remaining:
        active = _principal_matrix(matrix, remaining)
        determinant = _determinant(active)
        if determinant == 0:
            return [0, 0]
        first = remaining[0]
        partner_position = None
        for position in range(1, len(remaining)):
            partner = remaining[position]
            if matrix[first][partner] == 0:
                continue
            # Inverse[first?] entry at (partner, first) is its signed cofactor
            # divided by det(A): remove row first and column partner.
            minor = [row[:position] + row[position + 1:] for row in active[1:]]
            if _determinant(minor) != 0:
                partner_position = position
                break
        if partner_position is None:
            return [0, 0]
        partner = remaining[partner_position]
        pairs.append((first, partner))
        remaining = [v for v in remaining if v != first and v != partner]
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
    parsed = _valid_frame(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    n, edges = parsed
    matrix = [[0] * n for _ in range(n)]
    for u, v, value in edges:
        matrix[u][v] = value
        matrix[v][u] = (-value) % FIELD_PRIME
    result = _cofactor_matching(matrix, list(range(n)))
    payload = b"".join(struct.pack("<q", value) for value in result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
