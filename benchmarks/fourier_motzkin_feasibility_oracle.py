"""Primary exact Fourier–Motzkin feasibility oracle for the bounded profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VARIABLES = 3
MAX_INEQUALITIES = 6
MAX_VALID_INPUT_LENGTH = 26
MAX_PARSEABLE_INPUT_LENGTH = 27
MAX_INTERMEDIATE_ROWS = 128


def _parse(values: Sequence[int] | None, *, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[list[int]]] | None:
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
    rows: list[list[int]] = []
    offset = 2
    for _ in range(count):
        coefficients = list(values[offset:offset + dimension])
        bound = values[offset + dimension]
        if any(coefficient < -3 or coefficient > 3 for coefficient in coefficients):
            return None
        if bound < -6 or bound > 6:
            return None
        row = [0] * (MAX_VARIABLES + 1)
        row[:dimension] = coefficients
        row[MAX_VARIABLES] = bound
        rows.append(row)
        offset += dimension + 1
    return dimension, rows


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return 1 for feasible, 0 for infeasible, or -1 for invalid framing."""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return -1
    dimension, rows = parsed

    for variable in range(dimension):
        positive = [row for row in rows if row[variable] > 0]
        negative = [row for row in rows if row[variable] < 0]
        reduced = [row.copy() for row in rows if row[variable] == 0]
        if positive and negative:
            for upper in positive:
                upper_scale = upper[variable]
                for lower in negative:
                    lower_scale = -lower[variable]
                    combined = [0] * (MAX_VARIABLES + 1)
                    for coordinate in range(dimension):
                        if coordinate != variable:
                            combined[coordinate] = (
                                lower_scale * upper[coordinate]
                                + upper_scale * lower[coordinate]
                            )
                    combined[MAX_VARIABLES] = (
                        lower_scale * upper[MAX_VARIABLES]
                        + upper_scale * lower[MAX_VARIABLES]
                    )
                    reduced.append(combined)
        if len(reduced) > MAX_INTERMEDIATE_ROWS:
            return -1
        rows = reduced

    return 0 if any(row[MAX_VARIABLES] < 0 for row in rows) else 1
