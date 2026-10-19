"""Source-order oracle for ANSIbench LINPACK's rolled dgefa/dgesl path."""
from __future__ import annotations

import math
from collections.abc import Sequence

MIN_N = 2
MAX_N = 4
MAX_MATRIX_VALUE = 8
MAX_RHS_VALUE = 32
MAX_PARSEABLE_INPUT_LENGTH = 22
INVALID_RESULT = -1e300


def _daxpy(n: int, factor: float, x: list[float], y: list[float]) -> None:
    if n <= 0 or factor == 0.0:
        return
    for i in range(n):
        y[i] = y[i] + factor * x[i]


def _factor(matrix: list[float], n: int) -> tuple[list[int], int]:
    pivots = [0] * n
    info = 0
    nm1 = n - 1
    if nm1 >= 0:
        for k in range(nm1):
            kp1 = k + 1
            # idamax chooses the first maximum because comparisons are strict >.
            l = k
            maximum = abs(matrix[n * k + k])
            for i in range(1, n - k):
                candidate = abs(matrix[n * k + k + i])
                if candidate > maximum:
                    l = k + i
                    maximum = candidate
            pivots[k] = l
            if matrix[n * k + l] != 0.0:
                if l != k:
                    matrix[n * k + l], matrix[n * k + k] = matrix[n * k + k], matrix[n * k + l]
                factor = -1.0 / matrix[n * k + k]
                for i in range(n - (k + 1)):
                    matrix[n * k + k + 1 + i] = factor * matrix[n * k + k + 1 + i]
                for j in range(kp1, n):
                    t = matrix[n * j + l]
                    if l != k:
                        matrix[n * j + l] = matrix[n * j + k]
                        matrix[n * j + k] = t
                    x = [matrix[n * k + k + 1 + i] for i in range(n - (k + 1))]
                    y = [matrix[n * j + k + 1 + i] for i in range(n - (k + 1))]
                    _daxpy(n - (k + 1), t, x, y)
                    for i in range(n - (k + 1)):
                        matrix[n * j + k + 1 + i] = y[i]
            else:
                info = k
    pivots[n - 1] = n - 1
    if matrix[n * (n - 1) + (n - 1)] == 0.0:
        info = n - 1
    return pivots, info


def _solve(matrix: list[float], pivots: list[int], rhs: list[float], n: int) -> None:
    nm1 = n - 1
    if nm1 >= 1:
        for k in range(nm1):
            l = pivots[k]
            t = rhs[l]
            if l != k:
                rhs[l] = rhs[k]
                rhs[k] = t
            x = [matrix[n * k + k + 1 + i] for i in range(n - (k + 1))]
            y = rhs[k + 1:]
            _daxpy(n - (k + 1), t, x, y)
            rhs[k + 1:] = y
    for kb in range(n):
        k = n - (kb + 1)
        rhs[k] = rhs[k] / matrix[n * k + k]
        t = -rhs[k]
        x = [matrix[n * k + i] for i in range(k)]
        y = rhs[:k]
        _daxpy(k, t, x, y)
        rhs[:k] = y


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values):
        return INVALID_RESULT
    n = values[0]
    if not MIN_N <= n <= MAX_N or len(values) != 1 + n * n + n:
        return INVALID_RESULT
    raw_matrix = values[1:1 + n * n]
    raw_rhs = values[1 + n * n:]
    if any(not -MAX_MATRIX_VALUE <= value <= MAX_MATRIX_VALUE for value in raw_matrix):
        return INVALID_RESULT
    if any(not -MAX_RHS_VALUE <= value <= MAX_RHS_VALUE for value in raw_rhs):
        return INVALID_RESULT
    matrix = [float(value) for value in raw_matrix]
    rhs = [float(value) for value in raw_rhs]
    pivots, info = _factor(matrix, n)
    if info != 0 or any(not math.isfinite(value) for value in matrix):
        return INVALID_RESULT
    _solve(matrix, pivots, rhs, n)
    if any(not math.isfinite(value) for value in rhs):
        return INVALID_RESULT
    total = 0.0
    for i in range(n):
        total += float(i + 1) * rhs[i]
    return total if math.isfinite(total) else INVALID_RESULT


oracle = expected_result
