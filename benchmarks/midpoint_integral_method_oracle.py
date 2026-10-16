"""Oracle for the four-function midpoint integral benchmark."""
from __future__ import annotations

import math

INVALID_RESULT = -1.0e300
MAX_INPUT_LENGTH = 5
EXACT_INPUT_LENGTH = 4


def _function(function_id: int, x: float) -> float:
    if function_id == 0:
        return math.sqrt(x) + math.log(x)
    if function_id == 1:
        return math.exp(-x) * (4.0 - math.pow(x, 2.0))
    if function_id == 2:
        return math.sqrt(2.0 * math.pow(x, 3.0) + 3.0)
    return x + math.log(2.0 * x + 1.0)


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != EXACT_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    function_id, intervals, a_milli, b_milli = values
    if (not 0 <= function_id <= 3 or not 2 <= intervals <= 64 or intervals % 2 != 0
            or not 0 <= a_milli < b_milli <= 10000):
        return INVALID_RESULT
    a = a_milli / 1000.0
    b = b_milli / 1000.0
    h = (b - a) / intervals
    xi = a
    total = 0.0
    for _ in range(intervals):
        total += _function(function_id, xi + h / 2.0)
        xi += h
    result = total * h
    return result if math.isfinite(result) else INVALID_RESULT
