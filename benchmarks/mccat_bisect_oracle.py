"""Independent oracle for the bounded McCat Sturm-bisection profile."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_N = 32
MAX_OUTPUT_BYTES = (MAX_N + 1) * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
EPSILON = 2.2204460492503131e-16


def _sturm(diagonal: list[float], off_diagonal: list[float],
           beta: list[float], x: float) -> int:
    negative_count = 0
    q = 1.0
    for index in range(len(diagonal)):
        if q != 0.0:
            q = (diagonal[index] - x) - beta[index] / q
        else:
            q = (diagonal[index] - x) - abs(off_diagonal[index]) / EPSILON
        if q < 0.0:
            negative_count += 1
    return negative_count


def _bisect(n: int) -> tuple[list[float], float, int]:
    diagonal = [0.0] * n
    off_diagonal = [0.0] * n
    beta = [0.0] * n
    for index in range(n):
        value = float(index + 1)
        diagonal[index] = value * value
        diagonal[index] = diagonal[index] * diagonal[index]
        off_diagonal[index] = float(index)
        beta[index] = off_diagonal[index] * off_diagonal[index]

    beta[0] = 0.0
    off_diagonal[0] = 0.0
    fudge = 1.01
    xmin = diagonal[n - 1] - fudge * abs(off_diagonal[n - 1])
    xmax = diagonal[n - 1] + fudge * abs(off_diagonal[n - 1])
    for index in range(n - 2, -1, -1):
        h = fudge * (abs(off_diagonal[index]) + abs(off_diagonal[index + 1]))
        if diagonal[index] + h > xmax:
            xmax = diagonal[index] + h
        if diagonal[index] - h < xmin:
            xmin = diagonal[index] - h

    eps2 = EPSILON * (xmax if xmin + xmax > 0.0 else -xmin)
    eps1 = EPSILON
    if eps1 <= 0.0:
        eps1 = eps2
    eps2 = 0.5 * eps1 + 7.0 * eps2

    eigenvalues = [0.0] * (n + 1)
    lower_bounds = [0.0] * (n + 1)
    x0 = xmax
    for index in range(n, 0, -1):
        eigenvalues[index] = xmax
        lower_bounds[index] = xmin

    iterations = 0
    for k in range(n, 0, -1):
        xu = xmin
        for index in range(k, 0, -1):
            if xu < lower_bounds[index]:
                xu = lower_bounds[index]
                break
        if x0 > eigenvalues[k]:
            x0 = eigenvalues[k]

        x1 = (xu + x0) / 2.0
        while x0 - xu > 2.0 * EPSILON * (abs(xu) + abs(x0)) + eps1:
            iterations += 1
            count = _sturm(diagonal, off_diagonal, beta, x1)
            if count < k:
                if count < 1:
                    xu = x1
                    lower_bounds[1] = x1
                else:
                    xu = x1
                    lower_bounds[count + 1] = x1
                    if eigenvalues[count] > x1:
                        eigenvalues[count] = x1
            else:
                x0 = x1
            x1 = (xu + x0) / 2.0
        eigenvalues[k] = (xu + x0) / 2.0

    return eigenvalues, eps2, iterations


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return the source-ordered eigenvalue/diagnostic vector as little-endian f64."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) > 2
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    if len(values) != 1 or not 2 <= values[0] <= MAX_N:
        return INVALID_RESULT, b""

    n = values[0]
    required = (n + 1) * 8
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, b""

    eigenvalues, eps2, iterations = _bisect(n)
    result_values = eigenvalues[2:n + 1] + [eps2, float(iterations)]
    output = struct.pack("<" + "d" * len(result_values), *result_values)
    return len(output), output
