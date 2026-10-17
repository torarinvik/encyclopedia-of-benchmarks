"""Oracle for the bounded Soboleva modified hyperbolic tangent vector map."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_VECTOR_LENGTH = 1
MAX_VECTOR_LENGTH = 32
MIN_COEFFICIENT = -2.0
MAX_COEFFICIENT = 2.0
MIN_SAMPLE = -20.0
MAX_SAMPLE = 20.0
MAX_VALID_INPUT_LENGTH = 5 + MAX_VECTOR_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_VECTOR_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _valid_parameters(
    values: Sequence[int | float] | None,
) -> tuple[int, float, float, float, float, list[float]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(not _finite_number(value) for value in values)
    ):
        return None

    count_value = float(values[0])
    if not count_value.is_integer():
        return None
    count = int(count_value)
    if not MIN_VECTOR_LENGTH <= count <= MAX_VECTOR_LENGTH:
        return None
    if len(values) != 5 + count:
        return None

    a_value, b_value, c_value, d_value = (float(value) for value in values[1:5])
    if any(
        not MIN_COEFFICIENT <= coefficient <= MAX_COEFFICIENT
        for coefficient in (a_value, b_value, c_value, d_value)
    ):
        return None
    vector = [float(value) for value in values[5:]]
    if any(not MIN_SAMPLE <= sample <= MAX_SAMPLE for sample in vector):
        return None
    return count, a_value, b_value, c_value, d_value, vector


def _evaluate(
    a_value: float,
    b_value: float,
    c_value: float,
    d_value: float,
    vector: Sequence[float],
) -> list[float]:
    output: list[float] = []
    for value in vector:
        numerator = math.exp(a_value * value) - math.exp(-b_value * value)
        denominator = math.exp(c_value * value) + math.exp(-d_value * value)
        output.append(numerator / denominator)
    return output


def expected_result(values: Sequence[int | float] | None) -> list[float] | None:
    """Return one activation value per vector element, or None for invalid input."""
    parameters = _valid_parameters(values)
    if parameters is None:
        return None
    count, a_value, b_value, c_value, d_value, vector = parameters
    output = _evaluate(a_value, b_value, c_value, d_value, vector)
    if len(output) != count or any(not math.isfinite(value) for value in output):
        return None
    return output


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return result code and output vector for the float64-slice ABI."""
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
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    parameters = _valid_parameters(values)
    if parameters is None:
        return INVALID_RESULT, []
    count, a_value, b_value, c_value, d_value, vector = parameters
    output = _evaluate(a_value, b_value, c_value, d_value, vector)
    if len(output) != count or any(not math.isfinite(value) for value in output):
        return INVALID_RESULT, []
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, []
    return len(output), output
