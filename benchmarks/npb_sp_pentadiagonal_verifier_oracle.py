"""Independent dense exact-arithmetic verifier for an NPB SP line system."""

from __future__ import annotations

from fractions import Fraction
import math
from typing import Sequence

MIN_N = 5
MAX_N = 16
MAX_INPUT_LENGTH = 1 + 6 * MAX_N
MAX_ABS_BAND = 2.0
MIN_DIAGONAL = 5.0
MAX_DIAGONAL = 16.0
MIN_DOMINANCE_MARGIN = 0.25
MAX_ABS_RHS = 64.0
ABSOLUTE_TOLERANCE = 1.0e-9
RELATIVE_TOLERANCE = 1.0e-9


def _decode(values: Sequence[float] | None, input_length: int | None,
            input_is_null: bool):
    if input_is_null or values is None:
        return None
    try:
        raw = tuple(values)
    except TypeError:
        return None
    length = len(raw) if input_length is None else input_length
    if (type(length) is not int or length != len(raw)
            or length < 1 + 6 * MIN_N or length > MAX_INPUT_LENGTH):
        return None
    if any(type(v) not in (int, float) or not math.isfinite(float(v)) for v in raw):
        return None
    n_float = float(raw[0])
    if n_float != math.floor(n_float) or not MIN_N <= n_float <= MAX_N:
        return None
    n = int(n_float)
    if length != 1 + 6 * n:
        return None
    arrays = [tuple(float(v) for v in raw[1 + j*n:1 + (j+1)*n]) for j in range(6)]
    l2, l1, d, u1, u2, b = arrays
    if (l2[0] != 0 or l2[1] != 0 or l1[0] != 0 or u1[-1] != 0
            or u2[-2] != 0 or u2[-1] != 0):
        return None
    for i in range(n):
        if (max(abs(l2[i]), abs(l1[i]), abs(u1[i]), abs(u2[i])) > MAX_ABS_BAND
                or not MIN_DIAGONAL <= d[i] <= MAX_DIAGONAL
                or not -MAX_ABS_RHS <= b[i] <= MAX_ABS_RHS
                or d[i] - abs(l2[i]) - abs(l1[i]) - abs(u1[i]) - abs(u2[i])
                < MIN_DOMINANCE_MARGIN):
            return None
    return n, *arrays


def _dense_solution(n: int, l2, l1, d, u1, u2, rhs) -> list[float] | None:
    matrix = [[Fraction(0) for _ in range(n + 1)] for _ in range(n)]
    for row in range(n):
        matrix[row][row] = Fraction.from_float(d[row])
        if row >= 1:
            matrix[row][row - 1] = Fraction.from_float(l1[row])
        if row >= 2:
            matrix[row][row - 2] = Fraction.from_float(l2[row])
        if row + 1 < n:
            matrix[row][row + 1] = Fraction.from_float(u1[row])
        if row + 2 < n:
            matrix[row][row + 2] = Fraction.from_float(u2[row])
        matrix[row][n] = Fraction.from_float(rhs[row])

    for column in range(n):
        pivot = max(range(column, n), key=lambda row: abs(matrix[row][column]))
        if matrix[pivot][column] == 0:
            return None
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        for row in range(column + 1, n):
            if matrix[row][column] == 0:
                continue
            factor = matrix[row][column] / matrix[column][column]
            for entry in range(column, n + 1):
                matrix[row][entry] -= factor * matrix[column][entry]

    answer = [Fraction(0)] * n
    for row in range(n - 1, -1, -1):
        remainder = matrix[row][n] - sum(
            matrix[row][column] * answer[column] for column in range(row + 1, n))
        answer[row] = remainder / matrix[row][row]
    return [float(value) for value in answer]


def expected_output(values: Sequence[float] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1, []
    n, l2, l1, d, u1, u2, rhs = parsed
    if (type(output_is_null) is not bool
            or output_capacity is not None and type(output_capacity) is not int):
        return -2, []
    if output_is_null or output_capacity is not None and output_capacity < n:
        return -2, []
    answer = _dense_solution(n, l2, l1, d, u1, u2, rhs)
    return (-1, []) if answer is None else (n, answer)


def agrees(left: Sequence[float], right: Sequence[float]) -> bool:
    return (len(left) == len(right)
            and all(math.isclose(a, b, rel_tol=RELATIVE_TOLERANCE,
                                 abs_tol=ABSOLUTE_TOLERANCE)
                    for a, b in zip(left, right)))
