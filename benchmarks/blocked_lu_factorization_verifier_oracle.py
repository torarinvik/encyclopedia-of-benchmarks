"""Independent scalar Doolittle verifier for blocked LU outputs."""

from __future__ import annotations

import math
from collections.abc import Sequence

from blocked_lu_factorization_oracle import (
    ABSOLUTE_TOLERANCE,
    INVALID_RESULT,
    MAX_DIAGONAL,
    MAX_DIMENSION,
    MAX_OFF_DIAGONAL,
    MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    WORKSPACE_BYTES,
    MIN_DIAGONAL,
    MIN_DIMENSION,
    MIN_OFF_DIAGONAL,
    OUTPUT_ERROR,
)

RELATIVE_TOLERANCE = ABSOLUTE_TOLERANCE


def _decode(values: Sequence[float] | None):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    raw_n = values[0]
    if type(raw_n) not in (int, float) or not math.isfinite(raw_n) or int(raw_n) != raw_n:
        return None
    n = int(raw_n)
    if not MIN_DIMENSION <= n <= MAX_DIMENSION or n % 2 or len(values) != 1 + n * n:
        return None
    matrix = [[0.0] * n for _ in range(n)]
    for row in range(n):
        magnitude = 0
        for col in range(n):
            raw = values[1 + row * n + col]
            if type(raw) not in (int, float) or not math.isfinite(raw) or int(raw) != raw:
                return None
            value = int(raw)
            if row == col:
                if not MIN_DIAGONAL <= value <= MAX_DIAGONAL:
                    return None
            else:
                if not MIN_OFF_DIAGONAL <= value <= MAX_OFF_DIAGONAL:
                    return None
                magnitude += abs(value)
            matrix[row][col] = float(value)
        if matrix[row][row] <= magnitude:
            return None
    return n, matrix


def _scalar_doolittle(a: list[list[float]]):
    n = len(a)
    l = [[0.0] * n for _ in range(n)]
    u = [[0.0] * n for _ in range(n)]
    for pivot in range(n):
        for col in range(pivot, n):
            residual = a[pivot][col]
            for k in range(pivot):
                residual -= l[pivot][k] * u[k][col]
            u[pivot][col] = residual
        diagonal = u[pivot][pivot]
        if diagonal == 0.0 or not math.isfinite(diagonal):
            return None
        l[pivot][pivot] = 1.0
        for row in range(pivot + 1, n):
            residual = a[row][pivot]
            for k in range(pivot):
                residual -= l[row][k] * u[k][pivot]
            l[row][pivot] = residual / diagonal
            if not math.isfinite(l[row][pivot]):
                return None
    return l, u


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
    n, a = decoded
    factors = _scalar_doolittle(a)
    if factors is None:
        return INVALID_RESULT, []
    lower, upper = factors
    flat = [value for row in lower for value in row]
    flat.extend(value for row in upper for value in row)
    if len(flat) > MAX_OUTPUT_ELEMENTS:
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < len(flat)):
        return OUTPUT_ERROR, []
    return 2 * n * n, flat
