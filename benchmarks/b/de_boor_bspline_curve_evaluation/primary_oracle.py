"""Local de Boor recursion for one bounded B-spline curve evaluation."""

from __future__ import annotations

import math
from collections.abc import Sequence

ALGORITHM = "de_boor_bspline_curve_evaluation"
MAX_DEGREE = 3
MAX_CONTROL_POINTS = 8
MAX_KNOTS = MAX_CONTROL_POINTS + MAX_DEGREE + 1
MAX_VALID_INPUT_LENGTH = 23
MAX_PARSEABLE_INPUT_LENGTH = 24
MAX_OUTPUT_ELEMENTS = 1
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
WORKSPACE_BYTES = 128


def _parse(values: Sequence[float] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, float, list[float], list[float]] | None:
    if (input_is_null or not isinstance(values, (tuple, list))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    try:
        numbers = [float(value) for value in values]
    except (TypeError, ValueError, OverflowError):
        return None
    if any(not math.isfinite(value) for value in numbers):
        return None
    if len(numbers) < 3:
        return None
    degree_value, count_value, parameter = numbers[:3]
    if (degree_value != math.trunc(degree_value)
            or count_value != math.trunc(count_value)):
        return None
    degree, count = int(degree_value), int(count_value)
    if not 1 <= degree <= MAX_DEGREE or not degree + 1 <= count <= MAX_CONTROL_POINTS:
        return None
    knot_count = count + degree + 1
    if len(numbers) != 3 + knot_count + count:
        return None
    knots = numbers[3:3 + knot_count]
    controls = numbers[3 + knot_count:]
    if (any(value < -1000.0 or value > 1000.0 for value in knots)
            or any(value < -1000.0 or value > 1000.0 for value in controls)):
        return None
    if any(knots[index] > knots[index + 1] for index in range(knot_count - 1)):
        return None
    run = 1
    for index in range(1, knot_count):
        if knots[index] == knots[index - 1]:
            run += 1
            if run > degree + 1:
                return None
        else:
            run = 1
    lower, upper = knots[degree], knots[count]
    if not lower < upper or not lower <= parameter <= upper:
        return None
    return degree, count, parameter, knots, controls


def _span(degree: int, count: int, parameter: float,
          knots: Sequence[float]) -> int:
    if parameter == knots[count]:
        return count - 1
    span = degree
    while span < count - 1 and parameter >= knots[span + 1]:
        span += 1
    return span


def de_boor_value(degree: int, count: int, parameter: float,
                  knots: Sequence[float], controls: Sequence[float]) -> float:
    span = _span(degree, count, parameter, knots)
    local = list(controls[span - degree:span + 1])
    for level in range(1, degree + 1):
        for slot in range(degree, level - 1, -1):
            left_index = span - degree + slot
            right_index = span + slot - level + 1
            denominator = knots[right_index] - knots[left_index]
            alpha = 0.0 if denominator == 0.0 else (
                (parameter - knots[left_index]) / denominator)
            local[slot] = (1.0 - alpha) * local[slot - 1] + alpha * local[slot]
    return local[degree]


def expected_output(values: Sequence[float] | None,
                    output_capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, []
    if (type(output_is_null) is not bool or output_is_null
            or type(output_capacity) is not int
            or output_capacity < MAX_OUTPUT_ELEMENTS):
        return OUTPUT_ERROR_RESULT, []
    value = de_boor_value(*parsed)
    return MAX_OUTPUT_ELEMENTS, [value]
