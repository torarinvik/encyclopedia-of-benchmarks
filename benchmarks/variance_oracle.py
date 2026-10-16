"""Source-order oracle for the bounded Julia sample-variance workload."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_VALUES = 64
MAX_INPUT_LENGTH = MAX_VALUES + 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_VALUES
            or any(type(value) is not int or not -1_000_000 <= value <= 1_000_000
                   for value in values)):
        return INVALID_RESULT
    average = sum(values) / len(values)
    squared_deviations = 0.0
    for value in values:
        squared_deviations += (value - average) ** 2
    return squared_deviations / (len(values) - 1)
