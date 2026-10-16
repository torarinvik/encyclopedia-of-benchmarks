"""Independent oracle for the bounded Poisson distribution package."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
MAX_MILLI_VALUE = 100_000
MAX_SUCCESS_COUNT = 20
MAX_INPUT_LENGTH = 5  # permits one extra value to reach the ABI as malformed input
SCALE = 1_000.0


def _point_probability(mean: float, successes: int) -> float:
    return (mean ** successes) * math.exp(-mean) / math.factorial(successes)


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Evaluate one of the four source functions for a validated packed input."""
    if (not isinstance(values, (list, tuple)) or len(values) != 4
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    operation, first_milli, second_milli, third = values
    if operation == 0:
        if (not 0 <= first_milli <= MAX_MILLI_VALUE
                or not 1 <= second_milli <= MAX_MILLI_VALUE or third != 0):
            return INVALID_RESULT
        events = first_milli / SCALE
        timeframe = second_milli / SCALE
        return events / timeframe

    if operation == 1:
        if (not 0 <= first_milli <= MAX_MILLI_VALUE
                or not 0 <= second_milli <= MAX_MILLI_VALUE or third != 0):
            return INVALID_RESULT
        rate = first_milli / SCALE
        time = second_milli / SCALE
        return rate * time

    if operation == 2:
        if (not 0 <= first_milli <= MAX_MILLI_VALUE
                or not 0 <= second_milli <= MAX_SUCCESS_COUNT or third != 0):
            return INVALID_RESULT
        return _point_probability(first_milli / SCALE, second_milli)

    if operation == 3:
        if (not 0 <= first_milli <= MAX_MILLI_VALUE
                or not 0 <= second_milli <= third <= MAX_SUCCESS_COUNT):
            return INVALID_RESULT
        mean = first_milli / SCALE
        return sum(_point_probability(mean, count)
                   for count in range(second_milli, third + 1))

    return INVALID_RESULT
