"""Exact-rational oracle for the bounded shared inverse_of_matrix contract."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_INPUT_VALUES = 11
MIN_DIMENSION = 2
MAX_DIMENSION = 3
MIN_COEFFICIENT_Q = -32
MAX_COEFFICIENT_Q = 32
COEFFICIENT_SCALE = 16
MAX_OUTPUT_VALUES = MAX_DIMENSION * MAX_DIMENSION
MAX_OUTPUT_BYTES = MAX_OUTPUT_VALUES * 8
MAX_ABSOLUTE_INVERSE = 32768.0
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12


def _determinant(matrix: list[list[int]]) -> int:
    size = len(matrix)
    if size == 1:
        return matrix[0][0]
    if size == 2:
        return matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0]
    return (
        matrix[0][0] * matrix[1][1] * matrix[2][2]
        + matrix[0][1] * matrix[1][2] * matrix[2][0]
        + matrix[0][2] * matrix[1][0] * matrix[2][1]
        - matrix[0][2] * matrix[1][1] * matrix[2][0]
        - matrix[0][1] * matrix[1][0] * matrix[2][2]
        - matrix[0][0] * matrix[1][2] * matrix[2][1]
    )


def _cofactor(matrix: list[list[int]], row: int, column: int) -> int:
    minor = [
        [value for j, value in enumerate(source_row) if j != column]
        for i, source_row in enumerate(matrix)
        if i != row
    ]
    value = _determinant(minor)
    return -value if (row + column) % 2 else value


def _inverse_q_matrix(values: Sequence[int] | None) -> list[list[Fraction]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None

    dimension = values[0]
    if not MIN_DIMENSION <= dimension <= MAX_DIMENSION:
        return None
    if len(values) != 1 + dimension * dimension:
        return None

    flat = values[1:]
    if any(not MIN_COEFFICIENT_Q <= value <= MAX_COEFFICIENT_Q for value in flat):
        return None
    matrix = [
        list(flat[row * dimension : (row + 1) * dimension])
        for row in range(dimension)
    ]

    # Each row has a unique strictly dominant column, and those columns form
    # a permutation. Reordering rows therefore yields a strictly diagonally
    # dominant matrix, a finite, nonsingular and well-conditioned subdomain.
    dominant_columns: list[int] = []
    for row in matrix:
        candidates = [
            column
            for column, value in enumerate(row)
            if abs(value) > sum(abs(other) for j, other in enumerate(row) if j != column)
        ]
        if len(candidates) != 1:
            return None
        dominant_columns.append(candidates[0])
    if sorted(dominant_columns) != list(range(dimension)):
        return None

    determinant_q = _determinant(matrix)
    if determinant_q == 0:
        return None

    adjugate_q = [
        [_cofactor(matrix, column, row) for column in range(dimension)]
        for row in range(dimension)
    ]
    inverse = [
        [Fraction(COEFFICIENT_SCALE * value, determinant_q) for value in row]
        for row in adjugate_q
    ]
    if any(abs(float(value)) > MAX_ABSOLUTE_INVERSE for row in inverse for value in row):
        return None
    return inverse


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and row-major little-endian inverse bytes."""
    if input_is_null:
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int
        or not isinstance(values, (list, tuple))
        or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    inverse = _inverse_q_matrix(values)
    if inverse is None:
        return INVALID_RESULT, b""

    flattened = [float(value) for row in inverse for value in row]
    output = struct.pack("<" + "d" * len(flattened), *flattened)
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output


def expected_result(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the ABI status/result code for a matrix input."""
    return expected_output(
        values, capacity, input_is_null, output_is_null, input_length
    )[0]


def expected_inverse(values: Sequence[int] | None) -> list[float] | None:
    """Return flattened row-major expected values for a valid matrix."""
    inverse = _inverse_q_matrix(values)
    if inverse is None:
        return None
    return [float(value) for row in inverse for value in row]

