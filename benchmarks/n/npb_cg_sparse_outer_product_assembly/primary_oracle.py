"""Triplet-generation reference for the bounded NAS CG matrix assembler."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_N = 16
MAX_NONZER = 4
MAX_INPUT_LENGTH = 3 + 2 * MAX_N * MAX_NONZER
MAX_OUTPUT_BYTES = 8 * (MAX_N + 3 + 2 * MAX_N * MAX_N)
MAX_SHIFT_MICRO = 10_000_000
MAX_VALUE_MICRO = 1_000_000
SCALE = 1_000_000.0
RCOND = 0.1
WORKSPACE_BYTES = 8192
ABSOLUTE_TOLERANCE = 1.0e-12
RELATIVE_TOLERANCE = 1.0e-12


def parse_input(values: Sequence[int] | None, input_is_null: bool = False,
                input_length: int | None = None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 3 <= input_length <= MAX_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    n, nonzer, shift_micro = values[:3]
    if (not 2 <= n <= MAX_N or not 1 <= nonzer <= MAX_NONZER
            or not 0 <= shift_micro <= MAX_SHIFT_MICRO
            or input_length != 3 + 2 * n * nonzer):
        return None
    vectors = []
    cursor = 3
    for vector_id in range(n):
        coordinates = []
        seen = set()
        for _ in range(nonzer):
            coordinate, value_micro = values[cursor:cursor + 2]
            cursor += 2
            if (not 0 <= coordinate < n or coordinate in seen
                    or value_micro == 0
                    or not -MAX_VALUE_MICRO <= value_micro <= MAX_VALUE_MICRO):
                return None
            seen.add(coordinate)
            coordinates.append((coordinate, value_micro / SCALE))
        anchor = next((position for position, item in enumerate(coordinates)
                       if item[0] == vector_id), None)
        if anchor is None:
            coordinates.append((vector_id, 0.5))
        else:
            coordinates[anchor] = (vector_id, 0.5)
        vectors.append(coordinates)
    return n, shift_micro / SCALE, vectors


def _triplets(parsed):
    n, shift, vectors = parsed
    triples = []
    for vector_id, support in enumerate(vectors):
        if vector_id == 0:
            weight = 1.0
        elif vector_id == n - 1:
            weight = RCOND
        else:
            weight = math.pow(RCOND, vector_id / (n - 1))
        # The outer support is the source column loop; the inner support is
        # the source row loop. Keeping that order pins duplicate addition.
        for column, column_value in support:
            scaled = weight * column_value
            for row, row_value in support:
                triples.append((row, column, row_value * scaled))
    diagonal_addend = RCOND - shift
    for diagonal in range(n):
        triples.append((diagonal, diagonal, diagonal_addend))
    return triples


def _coalesce(parsed):
    n, _shift, _vectors = parsed
    triples = _triplets(parsed)
    column_pointers = [0]
    row_indices = []
    matrix_values = []
    for column in range(n):
        for row in range(n):
            total = 0.0
            touched = False
            for triple_row, triple_column, value in triples:
                if triple_row == row and triple_column == column:
                    total += value
                    touched = True
            if touched:
                row_indices.append(row)
                matrix_values.append(total)
        column_pointers.append(len(row_indices))
    return column_pointers, row_indices, matrix_values


def _encode(n, column_pointers, row_indices, matrix_values):
    words = [float(n), float(len(row_indices)),
             *(float(value) for value in column_pointers),
             *(float(value) for value in row_indices), *matrix_values]
    return struct.pack("<" + "d" * len(words), *words)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    parsed = parse_input(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n = parsed[0]
    column_pointers, row_indices, matrix_values = _coalesce(parsed)
    required = 8 * (2 + (n + 1) + 2 * len(row_indices))
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0 or output_is_null or capacity < required):
        return -2, b""
    return required, _encode(n, column_pointers, row_indices, matrix_values)

