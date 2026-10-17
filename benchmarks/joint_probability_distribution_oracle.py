"""Oracle for the bounded Cartesian joint probability distribution adapter."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_SUPPORT_LENGTH = 4
MAX_INPUT_LENGTH = 2 + 4 * MAX_SUPPORT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 2
MAX_SUPPORT_VALUE = 1_000
MAX_ABS_PROBABILITY = 1_000_000.0
MAX_OUTPUT_ELEMENTS = 3 * MAX_SUPPORT_LENGTH * MAX_SUPPORT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except (OverflowError, ValueError):
        return False


def expected_output(
    values: Sequence[int | float], output_capacity: int | None = None
) -> tuple[int, list[float]]:
    """Return `[x,y,px*py,...]` in the source's x-major iteration order."""
    if (not isinstance(values, (list, tuple))
            or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(not _finite_number(value) for value in values)):
        return INVALID_RESULT, []

    nx_value, ny_value = float(values[0]), float(values[1])
    if (not nx_value.is_integer() or not ny_value.is_integer()
            or not 1 <= nx_value <= MAX_SUPPORT_LENGTH
            or not 1 <= ny_value <= MAX_SUPPORT_LENGTH):
        return INVALID_RESULT, []
    nx, ny = int(nx_value), int(ny_value)
    expected_length = 2 + 2 * nx + 2 * ny
    if len(values) != expected_length:
        return INVALID_RESULT, []

    x_start = 2
    y_start = x_start + nx
    x_probability_start = y_start + ny
    y_probability_start = x_probability_start + nx
    x_values = [float(value) for value in values[x_start:y_start]]
    y_values = [float(value) for value in values[y_start:x_probability_start]]
    x_probabilities = [float(value) for value in values[x_probability_start:y_probability_start]]
    y_probabilities = [float(value) for value in values[y_probability_start:]]

    supports = (x_values, y_values)
    for support in supports:
        if any(value != math.trunc(value) or abs(value) > MAX_SUPPORT_VALUE for value in support):
            return INVALID_RESULT, []
        if len(set(support)) != len(support):
            return INVALID_RESULT, []
    probabilities = x_probabilities + y_probabilities
    if any(abs(value) > MAX_ABS_PROBABILITY for value in probabilities):
        return INVALID_RESULT, []

    output: list[float] = []
    for x, x_probability in zip(x_values, x_probabilities):
        for y, y_probability in zip(y_values, y_probabilities):
            output.extend((float(int(x)), float(int(y)), x_probability * y_probability))

    if (output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID_RESULT, []
    if output_capacity is not None and len(output) > output_capacity:
        return OUTPUT_ERROR, []
    return len(output), output
