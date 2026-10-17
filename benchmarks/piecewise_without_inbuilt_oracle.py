"""Independent oracle for the bounded MATLAB/Octave piecewise activation."""

from __future__ import annotations

import math

INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 64
MAX_OUTPUT_ELEMENTS = 1
MIN_X = -10.0
MAX_X = 10.0
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    """Return the single piecewise output, or None when the packed input is invalid."""
    if (not isinstance(values, (list, tuple)) or len(values) != INPUT_LENGTH
            or type(values[0]) not in (int, float)):
        return None
    try:
        x = float(values[0])
    except (OverflowError, ValueError):
        return None
    if not math.isfinite(x) or x < MIN_X or x > MAX_X:
        return None
    if x <= -0.5:
        return [0.0]
    if x < 0.5:
        return [x]
    return [1.0]
