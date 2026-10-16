"""Oracle for the bounded Java quadratic-equation solver components."""

from __future__ import annotations

import math

MAX_COEFFICIENT = 1_000_000
MAX_INPUT_LENGTH = 5  # admit one extra packed value for malformed-input coverage
INVALID_RESULT = -1e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    if len(values) != 4:
        return INVALID_RESULT
    a, b, c, component = values
    if (not -MAX_COEFFICIENT <= a <= MAX_COEFFICIENT or a == 0
            or not -MAX_COEFFICIENT <= b <= MAX_COEFFICIENT
            or not -MAX_COEFFICIENT <= c <= MAX_COEFFICIENT
            or not 0 <= component <= 3):
        return INVALID_RESULT

    discriminant = b * b - 4 * a * c
    if discriminant > 0:
        sqrt_discriminant = math.sqrt(discriminant)
        roots = ((-b + sqrt_discriminant) / (2.0 * a),
                 (-b - sqrt_discriminant) / (2.0 * a))
        return roots[component] if component < 2 else INVALID_RESULT
    if discriminant == 0:
        return -b / (2.0 * a) if component == 0 else INVALID_RESULT

    real_part = -b / (2.0 * a)
    imaginary_part = math.sqrt(-discriminant) / (2.0 * a)
    if component < 2:
        return real_part
    return imaginary_part if component == 2 else -imaginary_part
