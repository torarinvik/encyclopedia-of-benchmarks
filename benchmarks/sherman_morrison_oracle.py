"""Bounded oracle for the pinned Sherman-Morrison matrix update."""

from __future__ import annotations

import math

MIN_DIMENSION = 1
MAX_DIMENSION = 4
MIN_ENTRY = -2
MAX_ENTRY = 2
MAX_VALID_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION + 2 * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _is_finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _parse_input(
        values: tuple[int | float, ...] | list[int | float],
        input_is_null: bool,
        input_length: int) -> tuple[int, list[list[float]], list[float], list[float]] | None:
    if (not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or type(input_is_null) is not bool
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or input_is_null and (values or input_length <= 0)
            or not input_is_null and (input_length != len(values) or input_length == 0)
            or any(not _is_finite_number(value) for value in values)):
        return None
    if input_is_null:
        return None

    dimension_value = float(values[0])
    if (not dimension_value.is_integer()
            or not MIN_DIMENSION <= dimension_value <= MAX_DIMENSION):
        return None
    dimension = int(dimension_value)
    expected_length = 1 + dimension * dimension + 2 * dimension
    if input_length != expected_length:
        return None

    coefficients: list[float] = []
    for value in values[1:]:
        numeric = float(value)
        if (not numeric.is_integer() or not MIN_ENTRY <= numeric <= MAX_ENTRY):
            return None
        coefficients.append(numeric)

    matrix_size = dimension * dimension
    inverse = [coefficients[row * dimension:(row + 1) * dimension]
               for row in range(dimension)]
    u = coefficients[matrix_size:matrix_size + dimension]
    v = coefficients[matrix_size + dimension:]
    return dimension, inverse, u, v


def _multiply(left: list[list[float]], right: list[list[float]]) -> list[list[float]]:
    """Multiply in the source Matrix.__mul__ row/column/inner-index order."""
    rows = len(left)
    inner = len(right)
    columns = len(right[0])
    result = [[0.0 for _ in range(columns)] for _ in range(rows)]
    for row in range(rows):
        for column in range(columns):
            for index in range(inner):
                result[row][column] += left[row][index] * right[index][column]
    return result


def _calculate(
        parsed: tuple[int, list[list[float]], list[float], list[float]]) -> tuple[int, tuple[float, ...]]:
    dimension, inverse, u, v = parsed
    u_column = [[value] for value in u]
    v_row = [v]

    # Preserve the source's left-associated `(v.T * self * u)` calculation.
    denominator = _multiply(_multiply(v_row, inverse), u_column)[0][0] + 1.0
    if denominator == 0.0:
        return 0, ()

    # Preserve `(self * u) * (v.T * self) * (1.0 / denominator)`.
    left_vector = _multiply(inverse, u_column)
    right_vector = _multiply(v_row, inverse)
    outer_product = _multiply(left_vector, right_vector)
    reciprocal = 1.0 / denominator
    updated = tuple(
        inverse[row][column] - outer_product[row][column] * reciprocal
        for row in range(dimension)
        for column in range(dimension)
    )
    return dimension * dimension, updated


def expected_result(values: tuple[int | float, ...] | list[int | float]) -> tuple[int, tuple[float, ...]]:
    """Return the ABI result and output for a valid non-null input slice."""
    parsed = _parse_input(values, False, len(values) if isinstance(values, (tuple, list)) else -1)
    if parsed is None:
        return INVALID_RESULT, ()
    return _calculate(parsed)


def expected_output(
        values: tuple[int | float, ...] | list[int | float],
        capacity: int = MAX_OUTPUT_ELEMENTS,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    """Model input precedence, Option output, null pointers, and output capacity."""
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    parsed = _parse_input(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_ELEMENTS
            or type(output_is_null) is not bool):
        return INVALID_RESULT, ()

    result, output = _calculate(parsed)
    if output_is_null:
        return OUTPUT_ERROR, ()
    if result == 0:
        return 0, ()
    if capacity < result:
        return OUTPUT_ERROR, ()
    return result, output
