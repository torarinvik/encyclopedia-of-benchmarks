"""Bounded source-semantics oracle for mean_absolute_percentage_error."""
import math

INVALID_RESULT = -1.0e300
SCALE = 1_000_000.0
EPSILON = 1e-15
MAX_COUNT = 64
MIN_SAMPLE = -1_000_000
MAX_SAMPLE = 1_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_COUNT

def mean_absolute_percentage_error(values):
    if values is None or len(values) < 1:
        return INVALID_RESULT
    a = list(values)
    n = a[0]
    if not (1 <= n <= MAX_COUNT) or len(a) != 1 + 2 * n:
        return INVALID_RESULT
    if any(x < MIN_SAMPLE or x > MAX_SAMPLE for x in a[1:]):
        return INVALID_RESULT
    total = 0.0
    for i in range(n):
        true_value = a[1 + i] / SCALE
        predicted = a[1 + n + i] / SCALE
        denominator = EPSILON if true_value == 0.0 else true_value
        total += abs((denominator - predicted) / denominator)
    return total / n


expected_result = mean_absolute_percentage_error
