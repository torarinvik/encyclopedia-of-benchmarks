"""Independent exact interval enumeration for the quantized average result."""

from __future__ import annotations

MAX_N = 32
MIN_VALUE = -1000
MAX_VALUE = 1000
SCALE = 1000
INVALID_RESULT = -1_000_001
MAX_VALID_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 35
MAX_WORKSPACE_BYTES = 1024


def expected_result(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if (len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT
    n, minimum_length = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= minimum_length <= n:
        return INVALID_RESULT
    if len(values) != n + 2:
        return INVALID_RESULT
    data = values[2:]
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in data):
        return INVALID_RESULT

    best_numerator = None
    best_denominator = 1
    for start in range(n):
        total = 0
        for end in range(start + 1, n + 1):
            total += data[end - 1]
            length = end - start
            if length < minimum_length:
                continue
            if (best_numerator is None
                    or total * best_denominator > best_numerator * length):
                best_numerator = total
                best_denominator = length
    assert best_numerator is not None
    # Python's // is mathematical floor, including for negative fractions.
    return (best_numerator * SCALE) // best_denominator
