"""Bounded oracle for the pinned raw R SVD ordinary least-squares routine."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_SAMPLE_COUNT = 2
MAX_SAMPLE_COUNT = 32
MIN_PREDICTOR = -4
MAX_PREDICTOR = 4
MIN_RESPONSE = -16
MAX_RESPONSE = 16
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_SAMPLE_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12


def _is_finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _exact_integer(value: object) -> int | None:
    if type(value) is int:
        return value
    if type(value) is not float or not math.isfinite(value) or not value.is_integer():
        return None
    return int(value)


def _parse_input(
    values: Sequence[int | float],
    input_is_null: bool,
    input_length: int,
) -> tuple[list[int], list[int]] | None:
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or type(input_is_null) is not bool
        or type(input_length) is not int
        or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
        or input_is_null and (values or input_length <= 0)
        or not input_is_null and (input_length != len(values) or input_length == 0)
        or any(not _is_finite_number(value) for value in values)
    ):
        return None
    if input_is_null:
        return None

    sample_count = _exact_integer(values[0])
    if sample_count is None or not MIN_SAMPLE_COUNT <= sample_count <= MAX_SAMPLE_COUNT:
        return None
    if input_length != 1 + 2 * sample_count:
        return None

    predictors: list[int] = []
    responses: list[int] = []
    for value in values[1:1 + sample_count]:
        integer = _exact_integer(value)
        if integer is None or not MIN_PREDICTOR <= integer <= MAX_PREDICTOR:
            return None
        predictors.append(integer)
    for value in values[1 + sample_count:]:
        integer = _exact_integer(value)
        if integer is None or not MIN_RESPONSE <= integer <= MAX_RESPONSE:
            return None
        responses.append(integer)

    if sum(predictors) != 0 or all(value == predictors[0] for value in predictors):
        return None
    return predictors, responses


def _calculate(parsed: tuple[list[int], list[int]]) -> tuple[float, float]:
    predictors, responses = parsed
    denominator = sum(value * value for value in predictors)
    intercept = sum(responses) / len(responses)
    slope = sum(x * y for x, y in zip(predictors, responses)) / denominator
    return float(intercept), float(slope)


def expected_result(values: Sequence[int | float]) -> tuple[float, float] | None:
    """Return [intercept, slope], or None for invalid packed input."""
    if not isinstance(values, (list, tuple)):
        return None
    parsed = _parse_input(values, False, len(values))
    if parsed is None:
        return None
    return _calculate(parsed)


def expected_output(
    values: Sequence[int | float],
    capacity: int = MAX_OUTPUT_ELEMENTS,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    """Model input validity, error precedence, and float64 slice capacity."""
    effective_length = (
        len(values)
        if input_length is None and isinstance(values, (list, tuple))
        else input_length
    )
    if effective_length is None:
        return INVALID_RESULT, ()
    parsed = _parse_input(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if (
        type(capacity) is not int
        or not 0 <= capacity <= MAX_OUTPUT_ELEMENTS
        or type(output_is_null) is not bool
    ):
        return INVALID_RESULT, ()
    if output_is_null or capacity < MAX_OUTPUT_ELEMENTS:
        return OUTPUT_ERROR, ()
    return MAX_OUTPUT_ELEMENTS, _calculate(parsed)
