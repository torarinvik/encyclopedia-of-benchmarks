"""Oracle for bounded positive-root Newton-Raphson workloads."""
from __future__ import annotations
import math
INVALID_RESULT = -1.0e300
MAX_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3

def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if not isinstance(values, (list, tuple)) or len(values) != 2 or any(type(v) is not int for v in values):
        return INVALID_RESULT
    radicand, start_quarters = values
    if not 2 <= radicand <= 4 or not 4 <= start_quarters <= 8:
        return INVALID_RESULT
    x = start_quarters / 4.0
    for _ in range(8):
        x = 0.5 * (x + radicand / x)
    return x if math.isfinite(x) else INVALID_RESULT
