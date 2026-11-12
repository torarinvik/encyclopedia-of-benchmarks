"""Direct banded-elimination oracle for a bounded NPB SP line solve."""

from __future__ import annotations

import math
from typing import Sequence

MIN_N = 5
MAX_N = 16
MAX_INPUT_LENGTH = 1 + 6 * MAX_N
MAX_OUTPUT_ELEMENTS = MAX_N
MAX_ABS_BAND = 2.0
MIN_DIAGONAL = 5.0
MAX_DIAGONAL = 16.0
MIN_DOMINANCE_MARGIN = 0.25
MAX_ABS_RHS = 64.0
ABSOLUTE_TOLERANCE = 1.0e-9
RELATIVE_TOLERANCE = 1.0e-9


def _parse(values: Sequence[float] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, list[float], list[float], list[float],
                                        list[float], list[float], list[float]] | None:
    if input_is_null or values is None:
        return None
    try:
        data = list(values)
    except TypeError:
        return None
    length = len(data) if input_length is None else input_length
    if (type(length) is not int or length != len(data)
            or length < 1 + 6 * MIN_N or length > MAX_INPUT_LENGTH):
        return None
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           for value in data):
        return None
    n_value = float(data[0])
    if n_value != math.trunc(n_value) or not MIN_N <= n_value <= MAX_N:
        return None
    n = int(n_value)
    if length != 1 + 6 * n:
        return None
    bands = [[float(value) for value in data[1 + band * n:1 + (band + 1) * n]
              ] for band in range(6)]
    lower2, lower1, diagonal, upper1, upper2, rhs = bands
    if (lower2[0] != 0.0 or lower2[1] != 0.0 or lower1[0] != 0.0
            or upper1[n - 1] != 0.0 or upper2[n - 2] != 0.0
            or upper2[n - 1] != 0.0):
        return None
    for row in range(n):
        off_diagonal = (lower2[row], lower1[row], upper1[row], upper2[row])
        if any(abs(value) > MAX_ABS_BAND for value in off_diagonal):
            return None
        if not MIN_DIAGONAL <= diagonal[row] <= MAX_DIAGONAL:
            return None
        if not -MAX_ABS_RHS <= rhs[row] <= MAX_ABS_RHS:
            return None
        margin = diagonal[row] - sum(abs(value) for value in off_diagonal)
        if margin < MIN_DOMINANCE_MARGIN:
            return None
    return n, lower2, lower1, diagonal, upper1, upper2, rhs


def _solve_banded(n: int, lower2: list[float], lower1: list[float],
                  diagonal: list[float], upper1: list[float],
                  upper2: list[float], rhs: list[float]) -> list[float]:
    """Eliminate at most two lower bands and back-substitute over two upper bands."""
    lo1 = lower1.copy()
    diag = diagonal.copy()
    up1 = upper1.copy()
    up2 = upper2.copy()
    work_rhs = rhs.copy()
    for pivot_row in range(n):
        pivot = diag[pivot_row]
        if pivot_row + 1 < n:
            row = pivot_row + 1
            factor = lo1[row] / pivot
            diag[row] -= factor * up1[pivot_row]
            up1[row] -= factor * up2[pivot_row]
            work_rhs[row] -= factor * work_rhs[pivot_row]
        if pivot_row + 2 < n:
            row = pivot_row + 2
            factor = lower2[row] / pivot
            lo1[row] -= factor * up1[pivot_row]
            diag[row] -= factor * up2[pivot_row]
            work_rhs[row] -= factor * work_rhs[pivot_row]

    solution = [0.0] * n
    for row in range(n - 1, -1, -1):
        value = work_rhs[row]
        if row + 1 < n:
            value -= up1[row] * solution[row + 1]
        if row + 2 < n:
            value -= up2[row] * solution[row + 2]
        solution[row] = value / diag[row]
    return solution


def expected_output(values: Sequence[float] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, []
    n, lower2, lower1, diagonal, upper1, upper2, rhs = parsed
    if (type(output_is_null) is not bool
            or output_capacity is not None and type(output_capacity) is not int):
        return -2, []
    if output_is_null or output_capacity is not None and output_capacity < n:
        return -2, []
    return n, _solve_banded(n, lower2, lower1, diagonal, upper1, upper2, rhs)


def validate_output(values: Sequence[float], output: Sequence[float]) -> bool:
    parsed = _parse(values, None, False)
    if parsed is None:
        return False
    n, lower2, lower1, diagonal, upper1, upper2, rhs = parsed
    if len(output) != n or any(not math.isfinite(float(value)) for value in output):
        return False
    for row, value in enumerate(output):
        reconstructed = diagonal[row] * value
        if row >= 1:
            reconstructed += lower1[row] * output[row - 1]
        if row >= 2:
            reconstructed += lower2[row] * output[row - 2]
        if row + 1 < n:
            reconstructed += upper1[row] * output[row + 1]
        if row + 2 < n:
            reconstructed += upper2[row] * output[row + 2]
        if not math.isclose(reconstructed, rhs[row], rel_tol=RELATIVE_TOLERANCE,
                            abs_tol=ABSOLUTE_TOLERANCE):
            return False
    return True
