"""Oracle for the final fully-defined point of fixed-window fractional differencing."""
from __future__ import annotations

INVALID_RESULT = -1e300
DEGREE_SCALE = 1_000_000
VALUE_SCALE = 1_000
MAX_WINDOW = 8
MAX_SERIES = 16
MAX_INPUT_LENGTH = MAX_SERIES + 2
MAX_VALUE_MILLI = 1_000_000


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return INVALID_RESULT
    degree_units, window, *series = values
    if not 0 <= degree_units <= DEGREE_SCALE or not 1 <= window <= MAX_WINDOW:
        return INVALID_RESULT
    if not window < len(series) <= MAX_SERIES or any(abs(x) > MAX_VALUE_MILLI for x in series):
        return INVALID_RESULT
    degree = degree_units / DEGREE_SCALE
    weights = [1.0]
    for k in range(1, window):
        weights.append(-weights[-1] * (degree - k + 1) / k)
    return sum(weights[j] * (series[-1 - j] / VALUE_SCALE) for j in range(window))
