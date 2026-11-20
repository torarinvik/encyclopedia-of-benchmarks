"""Recurrence evaluation of Hickerson's near-integer expression."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1e300
MIN_N = 1
MAX_N = 17


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not MIN_N <= values[0] <= MAX_N):
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != 1):
        return INVALID_RESULT
    n = values[0]
    log_two = math.log(2.0)
    value = 1.0 / (2.0 * log_two * log_two)
    for index in range(2, n + 1):
        value = (index / log_two) * value
    return value


expected_output = expected_result
