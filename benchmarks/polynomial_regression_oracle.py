"""Oracle for the bounded polynomial regression fit-and-predict workload."""

from __future__ import annotations

import math
from collections.abc import Sequence
from fractions import Fraction

MIN_DEGREE = 0
MAX_DEGREE = 3
MAX_TRAINING_COUNT = 5
MIN_QUERY_COUNT = 1
MAX_QUERY_COUNT = 4
MIN_ABSCISSA = -2
MAX_ABSCISSA = 2
MIN_RESPONSE = -32
MAX_RESPONSE = 32
MAX_VALID_INPUT_LENGTH = 3 + 2 * MAX_TRAINING_COUNT + MAX_QUERY_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_DEGREE + 1 + MAX_QUERY_COUNT
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-9
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _exact_integer(value: int | float) -> int | None:
    if type(value) is int:
        return value
    if type(value) is not float or not math.isfinite(value) or not value.is_integer():
        return None
    return int(value)


def _decode_input(values: Sequence[float] | None):
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None

    degree = _exact_integer(values[0])
    training_count = _exact_integer(values[1])
    query_count = _exact_integer(values[2])
    if degree is None or not MIN_DEGREE <= degree <= MAX_DEGREE:
        return None
    if training_count is None or not degree + 1 <= training_count <= MAX_TRAINING_COUNT:
        return None
    if query_count is None or not MIN_QUERY_COUNT <= query_count <= MAX_QUERY_COUNT:
        return None
    if len(values) != 3 + 2 * training_count + query_count:
        return None

    index = 3
    x_train = [_exact_integer(value) for value in values[index : index + training_count]]
    index += training_count
    y_train = [_exact_integer(value) for value in values[index : index + training_count]]
    index += training_count
    x_query = [_exact_integer(value) for value in values[index:]]

    if any(
        value is None or not MIN_ABSCISSA <= value <= MAX_ABSCISSA
        for value in x_train + x_query
    ):
        return None
    if len(set(x_train)) != training_count:
        return None
    if any(value is None or not MIN_RESPONSE <= value <= MAX_RESPONSE for value in y_train):
        return None

    return degree, x_train, y_train, x_query


def _solve_exact(matrix: list[list[Fraction]], rhs: list[Fraction]) -> list[Fraction]:
    """Solve the small nonsingular system using exact rational elimination."""
    size = len(rhs)
    augmented = [row[:] + [rhs[index]] for index, row in enumerate(matrix)]
    for column in range(size):
        pivot = next(row for row in range(column, size) if augmented[row][column] != 0)
        augmented[column], augmented[pivot] = augmented[pivot], augmented[column]
        pivot_value = augmented[column][column]
        augmented[column] = [value / pivot_value for value in augmented[column]]
        for row in range(size):
            if row == column:
                continue
            factor = augmented[row][column]
            if factor:
                augmented[row] = [
                    value - factor * pivot_entry
                    for value, pivot_entry in zip(augmented[row], augmented[column])
                ]
    return [augmented[row][-1] for row in range(size)]


def _fit_and_predict(
    degree: int,
    x_train: list[int],
    y_train: list[int],
    x_query: list[int],
) -> list[float]:
    columns = degree + 1
    # Since all inputs are integers, the bounded full-rank normal equations can
    # be accumulated exactly and yield the same unique least-squares solution
    # as the pinned source's SVD pseudoinverse.
    normal = [
        [
            Fraction(sum(x ** (row + col) for x in x_train))
            for col in range(columns)
        ]
        for row in range(columns)
    ]
    rhs = [
        Fraction(sum((x**power) * y for x, y in zip(x_train, y_train)))
        for power in range(columns)
    ]
    parameters = [float(value) for value in _solve_exact(normal, rhs)]

    output = parameters[:]
    for x in x_query:
        prediction = 0.0
        for power, parameter in enumerate(parameters):
            prediction += (x**power) * parameter
        output.append(prediction)
    return output


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return coefficients followed by predictions, or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, []
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, []
    degree, x_train, y_train, x_query = decoded
    output = _fit_and_predict(degree, x_train, y_train, x_query)

    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
