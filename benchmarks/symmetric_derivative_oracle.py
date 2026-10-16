"""Bounded source-derived centered-difference derivative oracle."""
from __future__ import annotations

import math

MAX_VALID_INPUT_LENGTH = 2
MAX_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 3
MIN_X_NANOUNITS = -6_300_000_000
MAX_X_NANOUNITS = 6_300_000_000
DEFAULT_STEP = 1e-10
INVALID_RESULT = -1e300


def expected_result(values: list[int]) -> float:
    if (
        not isinstance(values, list)
        or len(values) != 2
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return INVALID_RESULT
    function_id, x_nanounits = values
    if function_id not in (0, 1) or not MIN_X_NANOUNITS <= x_nanounits <= MAX_X_NANOUNITS:
        return INVALID_RESULT

    x = x_nanounits / 1_000_000_000.0
    function = math.sin if function_id == 0 else math.exp
    return (function(x + DEFAULT_STEP) - function(x - DEFAULT_STEP)) / (2.0 * DEFAULT_STEP)
