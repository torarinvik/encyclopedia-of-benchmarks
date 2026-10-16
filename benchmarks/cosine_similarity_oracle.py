"""Independent oracle for case-insensitive printable-ASCII cosine similarity."""

from __future__ import annotations

import math

MAX_STRING_LENGTH = 64
MAX_PARSEABLE_STRING_LENGTH = 65
MAX_INPUT_LENGTH = 2 + 2 * MAX_PARSEABLE_STRING_LENGTH
MIN_PRINTABLE_ASCII = 32
MAX_PRINTABLE_ASCII = 126
INVALID_RESULT = -1e300


def expected_output(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT

    left_length, right_length = values[0], values[1]
    if not 0 <= left_length <= MAX_STRING_LENGTH or not 0 <= right_length <= MAX_STRING_LENGTH:
        return INVALID_RESULT
    if len(values) != 2 + left_length + right_length:
        return INVALID_RESULT
    symbols = values[2:]
    if any(not MIN_PRINTABLE_ASCII <= value <= MAX_PRINTABLE_ASCII for value in symbols):
        return INVALID_RESULT

    left_counts = [0] * (MAX_PRINTABLE_ASCII - MIN_PRINTABLE_ASCII + 1)
    right_counts = [0] * len(left_counts)
    for value in values[2:2 + left_length]:
        folded = value + 32 if 65 <= value <= 90 else value
        left_counts[folded - MIN_PRINTABLE_ASCII] += 1
    for value in values[2 + left_length:]:
        folded = value + 32 if 65 <= value <= 90 else value
        right_counts[folded - MIN_PRINTABLE_ASCII] += 1

    dot_product = sum(left * right for left, right in zip(left_counts, right_counts))
    left_magnitude_squared = sum(count * count for count in left_counts)
    right_magnitude_squared = sum(count * count for count in right_counts)
    if left_magnitude_squared == 0 or right_magnitude_squared == 0:
        return 0.0
    return dot_product / (math.sqrt(left_magnitude_squared) * math.sqrt(right_magnitude_squared))
