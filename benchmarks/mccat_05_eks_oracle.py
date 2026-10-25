"""Independent cyclic-Jacobi oracle for the bounded McCat 05-eks profile."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MIN_N = 3
MAX_N = 8
MIN_BANDWIDTH = 2
MAX_BANDWIDTH = 5
MAX_INPUT_LENGTH = 2 + MAX_N * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = MAX_N * 4
INPUT_SCALE = 1_000_000
OUTPUT_SCALE = 1_000
INVALID_RESULT = -1
OUTPUT_ERROR = -2
JACOBI_TOLERANCE = 1.0e-14
MAX_JACOBI_SWEEPS = 256


def _decode(values: Sequence[int]) -> tuple[list[list[float]], int] | None:
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    n, bandwidth = values[0], values[1]
    if not MIN_N <= n <= MAX_N:
        return None
    if not MIN_BANDWIDTH <= bandwidth <= MAX_BANDWIDTH or bandwidth >= n:
        return None
    if len(values) != 2 + n * n:
        return None
    matrix = [[0.0] * n for _ in range(n)]
    for row in range(n):
        for column in range(n):
            integer = values[2 + row * n + column]
            if not -INPUT_SCALE <= integer <= INPUT_SCALE:
                return None
            if row > column and integer != values[2 + column * n + row]:
                return None
            if abs(row - column) > bandwidth and integer != 0:
                return None
            matrix[row][column] = integer / INPUT_SCALE
    return matrix, n


def _cyclic_jacobi(matrix: list[list[float]]) -> list[float] | None:
    """Diagonalize by cyclic Jacobi rotations, independent of source QR."""
    n = len(matrix)
    a = [row[:] for row in matrix]
    for _ in range(MAX_JACOBI_SWEEPS):
        largest = max(abs(a[row][column])
                      for row in range(n) for column in range(row + 1, n))
        if largest <= JACOBI_TOLERANCE:
            diagonal = [a[i][i] for i in range(n)]
            return diagonal if all(math.isfinite(value) for value in diagonal) else None
        for p in range(n - 1):
            for q in range(p + 1, n):
                apq = a[p][q]
                if abs(apq) <= JACOBI_TOLERANCE:
                    continue
                tau = (a[q][q] - a[p][p]) / (2.0 * apq)
                sign = -1.0 if tau < 0.0 else 1.0
                t = sign / (abs(tau) + math.sqrt(1.0 + tau * tau))
                c = 1.0 / math.sqrt(1.0 + t * t)
                s = t * c
                app, aqq = a[p][p], a[q][q]
                for k in range(n):
                    if k == p or k == q:
                        continue
                    akp, akq = a[k][p], a[k][q]
                    a[k][p] = a[p][k] = c * akp - s * akq
                    a[k][q] = a[q][k] = s * akp + c * akq
                a[p][p] = app - t * apq
                a[q][q] = aqq + t * apq
                a[p][q] = a[q][p] = 0.0
    return None


def _project(value: float) -> int:
    scaled = value * OUTPUT_SCALE
    return math.floor(scaled + 0.5) if scaled >= 0.0 else math.ceil(scaled - 0.5)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return signed i32 little-endian projected eigenvalues."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT, b""
    matrix, n = decoded
    required = n * 4
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, b""
    eigenvalues = _cyclic_jacobi(matrix)
    if eigenvalues is None:
        return INVALID_RESULT, b""
    eigenvalues.sort(key=lambda value: (-abs(value), value))
    projected = [_project(value) for value in eigenvalues]
    try:
        encoded = struct.pack("<" + "i" * n, *projected)
    except (OverflowError, struct.error):
        return INVALID_RESULT, b""
    return len(encoded), encoded
