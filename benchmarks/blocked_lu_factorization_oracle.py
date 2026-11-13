"""Primary blocked right-looking LU oracle for the bounded B=2 profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_DIMENSION = 2
MAX_DIMENSION = 8
BLOCK_WIDTH = 2
MIN_DIAGONAL = 1
MAX_DIAGONAL = 16
MIN_OFF_DIAGONAL = -2
MAX_OFF_DIAGONAL = 2
MAX_VALID_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_DIMENSION * MAX_DIMENSION
MAX_OUTPUT_BYTES = MAX_OUTPUT_ELEMENTS * 8
WORKSPACE_BYTES = 2560
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


def _decode(values: Sequence[float] | None):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    n = _integer(values[0])
    if n is None or n < MIN_DIMENSION or n > MAX_DIMENSION or n % 2:
        return None
    if len(values) != 1 + n * n:
        return None
    entries = [_integer(value) for value in values[1:]]
    if any(value is None for value in entries):
        return None
    matrix = [[0.0] * n for _ in range(n)]
    for row in range(n):
        row_sum = 0
        for col in range(n):
            value = entries[row * n + col]
            if row == col:
                if not MIN_DIAGONAL <= value <= MAX_DIAGONAL:
                    return None
            else:
                if not MIN_OFF_DIAGONAL <= value <= MAX_OFF_DIAGONAL:
                    return None
                row_sum += abs(value)
            matrix[row][col] = float(value)
        if matrix[row][row] <= row_sum:
            return None
    return n, matrix


def _blocked_factor(matrix: list[list[float]]) -> tuple[list[list[float]], list[list[float]]] | None:
    n = len(matrix)
    schur = [row[:] for row in matrix]
    lower = [[0.0] * n for _ in range(n)]
    upper = [[0.0] * n for _ in range(n)]

    for k in range(0, n, BLOCK_WIDTH):
        u00 = schur[k][k]
        if not math.isfinite(u00) or u00 == 0.0:
            return None
        u01 = schur[k][k + 1]
        l10 = schur[k + 1][k] / u00
        u11 = schur[k + 1][k + 1] - l10 * u01
        if not math.isfinite(l10) or not math.isfinite(u11) or u11 == 0.0:
            return None

        lower[k][k] = 1.0
        lower[k + 1][k] = l10
        lower[k + 1][k + 1] = 1.0
        upper[k][k] = u00
        upper[k][k + 1] = u01
        upper[k + 1][k + 1] = u11

        for j in range(k + BLOCK_WIDTH, n, BLOCK_WIDTH):
            for col in range(j, j + BLOCK_WIDTH):
                s0 = schur[k][col]
                s1 = schur[k + 1][col]
                upper[k][col] = s0
                upper[k + 1][col] = s1 - l10 * s0

        for i in range(k + BLOCK_WIDTH, n, BLOCK_WIDTH):
            for row in range(i, i + BLOCK_WIDTH):
                s0 = schur[row][k]
                s1 = schur[row][k + 1]
                l0 = s0 / u00
                l1 = (s1 - l0 * u01) / u11
                lower[row][k] = l0
                lower[row][k + 1] = l1

        for i in range(k + BLOCK_WIDTH, n, BLOCK_WIDTH):
            for j in range(k + BLOCK_WIDTH, n, BLOCK_WIDTH):
                for row in range(i, i + BLOCK_WIDTH):
                    for col in range(j, j + BLOCK_WIDTH):
                        update = lower[row][k] * upper[k][col]
                        update += lower[row][k + 1] * upper[k + 1][col]
                        schur[row][col] -= update

    if any(not math.isfinite(value) for row in lower for value in row):
        return None
    if any(not math.isfinite(value) for row in upper for value in row):
        return None
    return lower, upper


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return full row-major L then U, with the float64 ABI error precedence."""
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
    factors = _blocked_factor(matrix)
    if factors is None:
        return INVALID_RESULT, []
    lower, upper = factors
    output = [value for row in lower for value in row]
    output.extend(value for row in upper for value in row)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return 2 * n * n, output
