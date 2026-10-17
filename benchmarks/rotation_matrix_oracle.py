"""Oracle for the bounded Julia 2D rotation matrix function."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 64
MAX_ANGLE = 1_000.0
MAX_OUTPUT_ELEMENTS = 4
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
    """Return the row-major 2x2 counterclockwise matrix for theta radians."""
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(not _finite_number(value) for value in values)
            or len(values) != MAX_INPUT_LENGTH):
        return INVALID_RESULT, []
    theta = float(values[0])
    if abs(theta) > MAX_ANGLE:
        return INVALID_RESULT, []

    cosine = math.cos(theta)
    sine = math.sin(theta)
    output = [cosine, -sine, sine, cosine]
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, []
        if output_capacity < MAX_OUTPUT_ELEMENTS:
            return OUTPUT_ERROR, []
    return MAX_OUTPUT_ELEMENTS, output
