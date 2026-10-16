"""Bounded oracle for the pinned Chebyshev linear-system iteration."""

from __future__ import annotations

import math
import struct

MAX_DIMENSION = 8
MAX_MATRIX_MICRO = 1_000_000_000
MAX_VECTOR_MICRO = 1_000_000_000
MAX_SPECTRAL_MICRO = 1_000_000_000
MAX_ITERATIONS = 1000
SCALE = 1_000_000.0
MAX_INPUT_LENGTH = 1 + MAX_DIMENSION**2 + 2 * MAX_DIMENSION + 4
MAX_OUTPUT_BYTES = MAX_DIMENSION * 8


def expected_output(values: list[int] | tuple[int, ...],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Return the solution vector as little-endian binary64 values."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""

    n = values[0]
    if not 1 <= n <= MAX_DIMENSION or len(values) != 1 + n * n + 2 * n + 4:
        return -1, b""
    matrix_end = 1 + n * n
    vector_end = matrix_end + 2 * n
    matrix_micro = values[1:matrix_end]
    b_micro = values[matrix_end:matrix_end + n]
    x0_micro = values[matrix_end + n:vector_end]
    min_eigen_micro, max_eigen_micro, max_iterations, tolerance_micro = values[vector_end:]
    if (any(not -MAX_MATRIX_MICRO <= item <= MAX_MATRIX_MICRO for item in matrix_micro)
            or any(not -MAX_VECTOR_MICRO <= item <= MAX_VECTOR_MICRO for item in b_micro)
            or any(not -MAX_VECTOR_MICRO <= item <= MAX_VECTOR_MICRO for item in x0_micro)
            or not 1 <= min_eigen_micro < max_eigen_micro <= MAX_SPECTRAL_MICRO
            or not 1 <= max_iterations <= MAX_ITERATIONS
            or not 1 <= tolerance_micro <= MAX_VECTOR_MICRO):
        return -1, b""

    matrix = [[matrix_micro[row * n + column] / SCALE for column in range(n)]
              for row in range(n)]
    b = [item / SCALE for item in b_micro]
    x = [item / SCALE for item in x0_micro]
    min_eigenvalue = min_eigen_micro / SCALE
    max_eigenvalue = max_eigen_micro / SCALE
    tolerance = tolerance_micro / SCALE
    residual = [b[row] - sum(matrix[row][column] * x[column] for column in range(n))
                for row in range(n)]
    direction = [0.0] * n
    d = (max_eigenvalue + min_eigenvalue) / 2.0
    c = (max_eigenvalue - min_eigenvalue) / 2.0
    alpha = 0.0
    alpha_previous = 0.0

    for iteration in range(max_iterations):
        residual_norm = math.sqrt(sum(item * item for item in residual))
        if residual_norm < tolerance:
            break
        if iteration == 0:
            alpha = 1.0 / d
            direction = residual.copy()
        else:
            half_step = c * alpha_previous / 2.0
            beta = half_step * half_step
            alpha = 1.0 / (d - beta / alpha_previous)
            direction = [residual[index] + (beta / alpha_previous) * direction[index]
                         for index in range(n)]

        x = [x[index] + alpha * direction[index] for index in range(n)]
        residual = [b[row] - sum(matrix[row][column] * x[column] for column in range(n))
                    for row in range(n)]
        alpha_previous = alpha

    output = struct.pack("<" + "d" * n, *x)
    if capacity is not None:
        if type(capacity) is not int or capacity < 0:
            return -1, b""
        if len(output) > capacity:
            return -2, b""
    return len(output), output
