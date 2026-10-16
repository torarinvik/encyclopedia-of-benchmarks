"""Source-backed oracle for the Java Sakoe-Chiba-band DTW distance."""

from __future__ import annotations

MAX_SERIES_LENGTH = 16
MAX_SAMPLE_VALUE = 1_000
INVALID_RESULT = -1e300
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the scalar distance from the pinned rolling-row recurrence."""
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    first_length, second_length, band = values[:3]
    if not (1 <= first_length <= MAX_SERIES_LENGTH
            and 1 <= second_length <= MAX_SERIES_LENGTH
            and abs(first_length - second_length) <= band <= MAX_SERIES_LENGTH):
        return INVALID_RESULT
    if len(values) != 3 + first_length + second_length:
        return INVALID_RESULT
    first = values[3:3 + first_length]
    second = values[3 + first_length:]
    if (any(abs(sample) > MAX_SAMPLE_VALUE for sample in first)
            or any(abs(sample) > MAX_SAMPLE_VALUE for sample in second)):
        return INVALID_RESULT

    previous = [float("inf")] * (second_length + 1)
    previous[0] = 0.0
    for row in range(1, first_length + 1):
        current = [float("inf")] * (second_length + 1)
        start = max(1, row - band)
        end = min(second_length, row + band)
        for column in range(start, end + 1):
            cost = abs(first[row - 1] - second[column - 1])
            best = min(previous[column], min(current[column - 1], previous[column - 1]))
            current[column] = cost + best
        previous = current
    return previous[second_length]
