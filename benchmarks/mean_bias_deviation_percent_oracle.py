"""Independent oracle for the bounded mean-bias-deviation percentage metric."""

from __future__ import annotations

MAX_COUNT = 64
MAX_PARSED_COUNT = 65
MAX_SAMPLE = 1_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_PARSED_COUNT
INVALID_RESULT = -1.0e300
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the source-ordered MBD percentage or the invalid sentinel."""
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    count = values[0]
    if (not 1 <= count <= MAX_COUNT
            or len(values) != 1 + 2 * count):
        return INVALID_RESULT

    predictions = values[1:1 + count]
    actual = values[1 + count:]
    if any(abs(value) > MAX_SAMPLE for value in predictions + actual):
        return INVALID_RESULT

    actual_sum = sum(actual)
    if actual_sum == 0:
        return INVALID_RESULT

    difference_sum = sum(prediction - observed
                         for prediction, observed in zip(predictions, actual))
    numerator = difference_sum / count
    denominator = actual_sum / count
    return float(numerator) / denominator * 100.0
