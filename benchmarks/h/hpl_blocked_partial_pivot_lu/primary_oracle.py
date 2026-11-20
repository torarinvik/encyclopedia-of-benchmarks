"""Blocked right-looking partial-pivot LU oracle for the bounded HPL profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_N = 2
MAX_N = 8
BLOCK_WIDTH = 2
ENTRY_MIN = -16
ENTRY_MAX = 16
MAX_VALID_INPUT_LENGTH = 1 + MAX_N * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_N + MAX_N * MAX_N
MAX_OUTPUT_BYTES = MAX_OUTPUT_ELEMENTS * 8
WORKSPACE_BYTES = 2048
ABSOLUTE_TOLERANCE = 1e-10
RELATIVE_TOLERANCE = 1e-10
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _integer(value: int | float) -> int | None:
    if type(value) is int:
        return value
    if type(value) is not float or not math.isfinite(value) or not value.is_integer():
        return None
    return int(value)


def _decode(values: Sequence[float] | None) -> tuple[int, list[list[float]]] | None:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    n = _integer(values[0])
    if n is None or not MIN_N <= n <= MAX_N or len(values) != 1 + n * n:
        return None
    matrix = [[0.0] * n for _ in range(n)]
    for row in range(n):
        for col in range(n):
            value = _integer(values[1 + row * n + col])
            if value is None or not ENTRY_MIN <= value <= ENTRY_MAX:
                return None
            matrix[row][col] = float(value)
    return n, matrix


def _blocked_factor(matrix: list[list[float]]) -> tuple[list[int], list[list[float]]] | None:
    """Factor in place by two-column panels, retaining compact LU and swaps."""
    n = len(matrix)
    pivots = [0] * n
    for panel in range(0, n, BLOCK_WIDTH):
        panel_end = min(panel + BLOCK_WIDTH, n)

        # Factor the panel. Each pivot search sees updates from earlier columns
        # in this same panel. Strict comparison preserves the lowest-row tie.
        for col in range(panel, panel_end):
            pivot_row = col
            pivot_magnitude = abs(matrix[col][col])
            for row in range(col + 1, n):
                magnitude = abs(matrix[row][col])
                if magnitude > pivot_magnitude:
                    pivot_magnitude = magnitude
                    pivot_row = row
            if not math.isfinite(pivot_magnitude) or pivot_magnitude == 0.0:
                return None
            pivots[col] = pivot_row
            if pivot_row != col:
                matrix[col], matrix[pivot_row] = matrix[pivot_row], matrix[col]

            diagonal = matrix[col][col]
            if not math.isfinite(diagonal) or diagonal == 0.0:
                return None
            for row in range(col + 1, n):
                matrix[row][col] /= diagonal
                if not math.isfinite(matrix[row][col]):
                    return None
                multiplier = matrix[row][col]
                for update_col in range(col + 1, panel_end):
                    matrix[row][update_col] -= multiplier * matrix[col][update_col]
                    if not math.isfinite(matrix[row][update_col]):
                        return None

        # Unit-lower triangular solve for the panel block row.
        for row in range(panel, panel_end):
            for col in range(panel_end, n):
                value = matrix[row][col]
                for inner in range(panel, row):
                    value -= matrix[row][inner] * matrix[inner][col]
                if not math.isfinite(value):
                    return None
                matrix[row][col] = value

        # Right-looking trailing update, with the panel inner sum in order.
        for row in range(panel_end, n):
            for col in range(panel_end, n):
                update = 0.0
                for inner in range(panel, panel_end):
                    update += matrix[row][inner] * matrix[inner][col]
                matrix[row][col] -= update
                if not math.isfinite(matrix[row][col]):
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
    """Return pivot indices then row-major compact LU, matching float64 ABI errors."""
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
    factor = _blocked_factor(matrix)
    if factor is None:
        return INVALID_RESULT, []
    pivots, compact = factor
    staged = [float(pivot) for pivot in pivots]
    staged.extend(value for row in compact for value in row)
    if output_is_null or (output_capacity is not None and output_capacity < len(staged)):
        return OUTPUT_ERROR, []
    return len(staged), staged
