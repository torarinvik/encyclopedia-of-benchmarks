"""Oracle for the bounded single-indeterminate polynomial operations."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_DEGREE = 0
MAX_DEGREE = 8
MIN_COEFFICIENT = -10.0
MAX_COEFFICIENT = 10.0
MIN_EVALUATION_POINT = -2.0
MAX_EVALUATION_POINT = 2.0
MIN_INTEGRAL_CONSTANT = -10.0
MAX_INTEGRAL_CONSTANT = 10.0
MAX_VALID_INPUT_LENGTH = 21
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_DEGREE + 1
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12
INVALID_RESULT = -1
OUTPUT_ERROR = -2

OP_ADD = 0
OP_SUBTRACT = 1
OP_MULTIPLY = 2
OP_EVALUATE = 3
OP_DERIVATIVE = 4
OP_INTEGRAL = 5


def _finite_number(value: int | float) -> float | None:
    if type(value) not in (int, float):
        return None
    try:
        number = float(value)
    except OverflowError:
        return None
    return number if math.isfinite(number) else None


def _exact_integer(value: int | float) -> int | None:
    number = _finite_number(value)
    if number is None or not number.is_integer():
        return None
    return int(number)


def _bounded_coefficients(values: Sequence[float], start: int, count: int):
    result: list[float] = []
    for value in values[start:start + count]:
        number = _finite_number(value)
        if (number is None
                or not MIN_COEFFICIENT <= number <= MAX_COEFFICIENT):
            return None
        result.append(number)
    return result


def _read_polynomial(values: Sequence[float], cursor: int):
    if cursor >= len(values):
        return None
    degree = _exact_integer(values[cursor])
    if degree is None or not MIN_DEGREE <= degree <= MAX_DEGREE:
        return None
    cursor += 1
    count = degree + 1
    if cursor + count > len(values):
        return None
    coefficients = _bounded_coefficients(values, cursor, count)
    if coefficients is None:
        return None
    return degree, coefficients, cursor + count


def _decode_input(values: Sequence[float] | None):
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(_finite_number(value) is None for value in values):
        return None

    operation = _exact_integer(values[0])
    if operation is None or not OP_ADD <= operation <= OP_INTEGRAL:
        return None

    first = _read_polynomial(values, 1)
    if first is None:
        return None
    degree_a, coefficients_a, cursor = first

    if operation in (OP_ADD, OP_SUBTRACT, OP_MULTIPLY):
        second = _read_polynomial(values, cursor)
        if second is None:
            return None
        degree_b, coefficients_b, cursor = second
        if cursor != len(values):
            return None
        return operation, degree_a, coefficients_a, degree_b, coefficients_b

    if operation == OP_DERIVATIVE:
        if cursor != len(values):
            return None
        return operation, degree_a, coefficients_a

    if cursor + 1 != len(values):
        return None
    parameter = _finite_number(values[cursor])
    if parameter is None:
        return None
    if operation == OP_EVALUATE:
        if not MIN_EVALUATION_POINT <= parameter <= MAX_EVALUATION_POINT:
            return None
    elif not MIN_INTEGRAL_CONSTANT <= parameter <= MAX_INTEGRAL_CONSTANT:
        return None
    return operation, degree_a, coefficients_a, parameter


def _multiply(
    degree_a: int,
    coefficients_a: Sequence[float],
    degree_b: int,
    coefficients_b: Sequence[float],
) -> tuple[int, list[float]]:
    coefficients = [0.0] * (degree_a + degree_b + 1)
    for i in range(degree_a + 1):
        for j in range(degree_b + 1):
            coefficients[i + j] += coefficients_a[i] * coefficients_b[j]
    return degree_a + degree_b, coefficients


def _add(
    degree_a: int,
    coefficients_a: Sequence[float],
    degree_b: int,
    coefficients_b: Sequence[float],
) -> tuple[int, list[float]]:
    if degree_a > degree_b:
        coefficients = list(coefficients_a)
        for i in range(degree_b + 1):
            coefficients[i] += coefficients_b[i]
        return degree_a, coefficients
    coefficients = list(coefficients_b)
    for i in range(degree_a + 1):
        coefficients[i] += coefficients_a[i]
    return degree_b, coefficients


def _compute(decoded) -> list[float] | None:
    operation = decoded[0]
    if operation in (OP_ADD, OP_SUBTRACT, OP_MULTIPLY):
        _, degree_a, coefficients_a, degree_b, coefficients_b = decoded
        if operation == OP_ADD:
            _, result = _add(degree_a, coefficients_a, degree_b, coefficients_b)
        elif operation == OP_SUBTRACT:
            # Mirror `self + polynomial_2 * Polynomial(0, [-1])` exactly.
            negated_degree_b, negated_coefficients_b = _multiply(
                degree_b, coefficients_b, 0, (-1.0,))
            _, result = _add(
                degree_a, coefficients_a, negated_degree_b, negated_coefficients_b)
        else:
            _, result = _multiply(degree_a, coefficients_a, degree_b, coefficients_b)
        return result

    if operation == OP_EVALUATE:
        _, degree, coefficients, substitution = decoded
        result = 0.0
        for i in range(degree + 1):
            result += coefficients[i] * (substitution ** i)
        return [result]

    if operation == OP_DERIVATIVE:
        _, degree, coefficients = decoded
        result = [0.0] * degree
        for i in range(degree):
            result[i] = coefficients[i + 1] * (i + 1)
        return result

    _, degree, coefficients, constant = decoded
    result = [0.0] * (degree + 2)
    result[0] = constant
    for i in range(degree + 1):
        result[i + 1] = coefficients[i] / (i + 1)
    return result


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return operation values or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, []
    output = _compute(decoded)
    if (len(output) > MAX_OUTPUT_ELEMENTS
            or any(not math.isfinite(value) for value in output)):
        return INVALID_RESULT, []
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, []
    return len(output), output
