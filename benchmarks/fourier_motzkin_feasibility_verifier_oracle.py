"""Independent exact vertex-enumeration oracle for FME feasibility frames."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
from itertools import combinations

from fourier_motzkin_feasibility_oracle import (
    MAX_INEQUALITIES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VARIABLES,
)

_WITNESS_BOUND = 10_000


def _parse(values: Sequence[int] | None, *, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[tuple[int, ...], int]]] | None:
    if input_is_null or values is None:
        return None
    actual_length = len(values)
    if input_length is None:
        input_length = actual_length
    if input_length != actual_length or actual_length < 2 or actual_length > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    dimension, count = values[0], values[1]
    if not 1 <= dimension <= MAX_VARIABLES or not 1 <= count <= MAX_INEQUALITIES:
        return None
    if actual_length != 2 + count * (dimension + 1):
        return None
    rows = []
    offset = 2
    for _ in range(count):
        coefficients = tuple(values[offset:offset + dimension])
        bound = values[offset + dimension]
        if any(coefficient < -3 or coefficient > 3 for coefficient in coefficients):
            return None
        if bound < -6 or bound > 6:
            return None
        rows.append((coefficients, bound))
        offset += dimension + 1
    return dimension, rows


def _solve_square(rows: tuple[tuple[tuple[int, ...], int], ...], dimension: int) -> tuple[Fraction, ...] | None:
    matrix = [
        [Fraction(value) for value in coefficients] + [Fraction(bound)]
        for coefficients, bound in rows
    ]
    for column in range(dimension):
        pivot = next((row for row in range(column, dimension) if matrix[row][column]), None)
        if pivot is None:
            return None
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        scale = matrix[column][column]
        matrix[column] = [value / scale for value in matrix[column]]
        for row in range(dimension):
            if row == column:
                continue
            factor = matrix[row][column]
            if factor:
                matrix[row] = [left - factor * right
                               for left, right in zip(matrix[row], matrix[column])]
    return tuple(matrix[row][-1] for row in range(dimension))


def _has_bounded_vertex(dimension: int,
                        rows: list[tuple[tuple[int, ...], int]]) -> bool:
    constraints = list(rows)
    for coordinate in range(dimension):
        positive = [0] * dimension
        positive[coordinate] = 1
        negative = [0] * dimension
        negative[coordinate] = -1
        constraints.append((tuple(positive), _WITNESS_BOUND))
        constraints.append((tuple(negative), _WITNESS_BOUND))

    for selected in combinations(constraints, dimension):
        candidate = _solve_square(selected, dimension)
        if candidate is None:
            continue
        if all(sum(coefficient * value for coefficient, value in zip(coefficients, candidate)) <= bound
               for coefficients, bound in constraints):
            return True
    return False


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Decide feasibility by enumerating vertices of a bounded exact polytope.

    Any feasible frame has a point with coordinates below 10,000 in magnitude:
    minimize t subject to the input inequalities and -t <= x_i <= t, t >= 0.
    An optimal basic solution has dimension at most four, input coefficients at
    most 3, and right sides at most 6, so Cramer's rule bounds each coordinate
    by 3,888. Intersecting with the wider box therefore preserves feasibility.
    """
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return -1
    dimension, rows = parsed
    return 1 if _has_bounded_vertex(dimension, rows) else 0
