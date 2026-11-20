"""Exact rational-system oracle with canonical guarded-binary64 fallback."""

from __future__ import annotations

import math
from collections.abc import Sequence
from fractions import Fraction

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_N = 1
MAX_N = 6
MAX_VALID_INPUT_LENGTH = 14
MAX_PARSEABLE_INPUT_LENGTH = 15
MAX_OUTPUT_ELEMENTS = 1
GRID_DENOMINATOR = 18_014_398_509_481_984
MIN_NODE_SEPARATION = Fraction(1, 16)
MIN_DENOMINATOR_MAGNITUDE = 1.0 / 32.0
MAX_INTERMEDIATE_MAGNITUDE = 64.0
BOUNDARY_GUARD = 1.0 / 4_294_967_296


def _valid_scalar(value: object) -> bool:
    if type(value) is int:
        return -8 <= value <= 8
    if type(value) is not float or not math.isfinite(value) or not -8.0 <= value <= 8.0:
        return False
    return (value * GRID_DENOMINATOR).is_integer()


def _parse(values: Sequence[int | float], input_is_null: bool,
           input_length: int) -> tuple[list[Fraction], list[Fraction], Fraction] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(not _valid_scalar(value) for value in values)):
        return None
    raw_n = float(values[0]) if values else math.nan
    if not raw_n.is_integer() or not MIN_N <= raw_n <= MAX_N:
        return None
    n = int(raw_n)
    if input_length != 2 + 2 * n:
        return None
    xs: list[Fraction] = []
    ys: list[Fraction] = []
    for index in range(n):
        x = float(values[1 + 2 * index])
        y = float(values[2 + 2 * index])
        if not (-8.0 <= x <= 8.0 and -8.0 <= y <= 8.0):
            return None
        exact_x = Fraction.from_float(x)
        if any(abs(exact_x - previous) < MIN_NODE_SEPARATION for previous in xs):
            return None
        xs.append(exact_x)
        ys.append(Fraction.from_float(y))
    query = float(values[-1])
    if not -8.0 <= query <= 8.0:
        return None
    return xs, ys, Fraction.from_float(query)


def _binary64_evaluate(xs: list[float], ys: list[float], query: float) -> float | None:
    """Return the canonical guarded binary64 result, or None for an invalid call."""
    n = len(xs)
    differences = [[0.0] * n for _ in range(n)]
    differences[0][:] = ys
    for order in range(1, n):
        for endpoint in range(order, n):
            denominator = differences[order - 1][order - 1] - differences[order - 1][endpoint]
            if (not math.isfinite(denominator)
                    or not MIN_DENOMINATOR_MAGNITUDE + BOUNDARY_GUARD < abs(denominator)
                    < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD):
                return None
            try:
                value = (xs[order - 1] - xs[endpoint]) / denominator
            except (OverflowError, ZeroDivisionError):
                return None
            if not math.isfinite(value) or abs(value) >= MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD:
                return None
            differences[order][endpoint] = value
        if not MIN_DENOMINATOR_MAGNITUDE + BOUNDARY_GUARD < abs(differences[order][order]) < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD:
            return None
    if query in xs or n == 1:
        return ys[xs.index(query)] if query in xs else ys[0]
    tail = differences[n - 1][n - 1]
    for order in range(n - 2, 0, -1):
        if (not math.isfinite(tail)
                or not MIN_DENOMINATOR_MAGNITUDE + BOUNDARY_GUARD < abs(tail)
                < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD):
            return None
        try:
            tail = differences[order][order] + (query - xs[order]) / tail
        except (OverflowError, ZeroDivisionError):
            return None
        if (not math.isfinite(tail)
                or not MIN_DENOMINATOR_MAGNITUDE + BOUNDARY_GUARD < abs(tail)
                < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD):
            return None
    if not MIN_DENOMINATOR_MAGNITUDE + BOUNDARY_GUARD < abs(tail) < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD:
        return None
    try:
        value = ys[0] + (query - xs[0]) / tail
    except (OverflowError, ZeroDivisionError):
        return None
    return value if math.isfinite(value) and abs(value) < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD else None


def _rational_linear_system(xs: list[Fraction], ys: list[Fraction], query: Fraction) -> Fraction | None:
    """Solve P(x_i)-y_i*Q(x_i)=0 as a homogeneous system, then evaluate P/Q."""
    n = len(xs)
    numerator_degree = n // 2
    denominator_degree = (n - 1) // 2
    width = numerator_degree + denominator_degree + 2
    matrix: list[list[Fraction]] = []
    for x, y in zip(xs, ys):
        row = [x ** power for power in range(numerator_degree + 1)]
        row.extend(-y * (x ** power) for power in range(denominator_degree + 1))
        matrix.append(row)

    pivot_columns: list[int] = []
    pivot_row = 0
    for column in range(width):
        candidate = next((row for row in range(pivot_row, n)
                          if matrix[row][column] != 0), None)
        if candidate is None:
            continue
        matrix[pivot_row], matrix[candidate] = matrix[candidate], matrix[pivot_row]
        pivot = matrix[pivot_row][column]
        matrix[pivot_row] = [entry / pivot for entry in matrix[pivot_row]]
        for row in range(n):
            if row == pivot_row:
                continue
            multiplier = matrix[row][column]
            if multiplier:
                matrix[row] = [entry - multiplier * pivot_entry
                               for entry, pivot_entry in zip(matrix[row], matrix[pivot_row])]
        pivot_columns.append(column)
        pivot_row += 1
        if pivot_row == n:
            break
    if pivot_row != n:
        return None
    free_column = next(column for column in range(width) if column not in pivot_columns)
    coefficients = [Fraction(0)] * width
    coefficients[free_column] = Fraction(1)
    for row, column in enumerate(pivot_columns):
        coefficients[column] = -matrix[row][free_column]
    split = numerator_degree + 1
    numerator = coefficients[:split]
    denominator = coefficients[split:]
    if not any(denominator):
        return None
    for x, y in zip(xs, ys):
        if sum(coefficient * x ** power for power, coefficient in enumerate(denominator)) == 0:
            return None
    if query in xs:
        return ys[xs.index(query)]
    denominator_value = sum(coefficient * query ** power
                            for power, coefficient in enumerate(denominator))
    if denominator_value == 0:
        return None
    numerator_value = sum(coefficient * query ** power
                          for power, coefficient in enumerate(numerator))
    result = numerator_value / denominator_value
    return result if abs(result) < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD else None


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    parsed = _parse(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    xs, ys, query = parsed
    binary64_result = _binary64_evaluate(
        [float(value) for value in xs], [float(value) for value in ys], float(query))
    if binary64_result is None:
        return INVALID_RESULT, ()
    exact_result = _rational_linear_system(xs, ys, query)
    # Exact rank loss or a rational pole is a cross-check outcome, not an
    # extra port precondition. The ordered binary64 table and guarded
    # continued fraction define status; use its value if exact algebra cannot
    # independently identify a unique rational result for this input.
    if exact_result is None:
        result = binary64_result
    else:
        try:
            exact_value = float(exact_result)
        except OverflowError:
            exact_value = math.inf
        result = (exact_value if math.isfinite(exact_value)
                  and abs(exact_value) < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD
                  else binary64_result)
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, ()
    if output_is_null or capacity < 1:
        return OUTPUT_ERROR, ()
    return 1, (result,)
