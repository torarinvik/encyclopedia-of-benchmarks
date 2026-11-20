"""Independent scalar partial-pivot LU reference for the bounded HPL profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_N,
    MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH,
    OUTPUT_ERROR,
    WORKSPACE_BYTES,
)


def _exact_integer(raw: int | float) -> int | None:
    if type(raw) is int:
        return raw
    if type(raw) is not float or not math.isfinite(raw) or not raw.is_integer():
        return None
    return int(raw)


def _decode(values: Sequence[float] | None) -> tuple[int, list[list[float]]] | None:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    n = _exact_integer(values[0])
    if n is None:
        return None
    if not 2 <= n <= MAX_N or len(values) != 1 + n * n:
        return None
    matrix = []
    for row in range(n):
        decoded_row = []
        for col in range(n):
            value = _exact_integer(values[1 + row * n + col])
            if value is None:
                return None
            if not -16 <= value <= 16:
                return None
            decoded_row.append(float(value))
        matrix.append(decoded_row)
    return n, matrix


def _scalar_factor(matrix: list[list[float]]) -> tuple[list[int], list[list[float]]] | None:
    """Conventional one-column-at-a-time elimination, independent of panel updates."""
    n = len(matrix)
    pivots: list[int] = []
    for col in range(n):
        pivot_row = max(range(col, n), key=lambda row: (abs(matrix[row][col]), -row))
        pivot_value = matrix[pivot_row][col]
        if not math.isfinite(pivot_value) or pivot_value == 0.0:
            return None
        pivots.append(pivot_row)
        if pivot_row != col:
            matrix[col], matrix[pivot_row] = matrix[pivot_row], matrix[col]
        diagonal = matrix[col][col]
        for row in range(col + 1, n):
            matrix[row][col] /= diagonal
            if not math.isfinite(matrix[row][col]):
                return None
            multiplier = matrix[row][col]
            for update_col in range(col + 1, n):
                matrix[row][update_col] -= multiplier * matrix[col][update_col]
                if not math.isfinite(matrix[row][update_col]):
                    return None
    if any(not math.isfinite(value) for row in matrix for value in row):
        return None
    return pivots, matrix


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, []
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []
    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT, []
    n, matrix = decoded
    factor = _scalar_factor(matrix)
    if factor is None:
        return INVALID_RESULT, []
    pivots, compact = factor
    staged = [float(pivot) for pivot in pivots]
    staged.extend(value for row in compact for value in row)
    if len(staged) > MAX_OUTPUT_ELEMENTS:
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < len(staged)):
        return OUTPUT_ERROR, []
    return len(staged), staged
