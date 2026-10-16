"""Bounded printable-ASCII oracle for TheAlgorithms/JavaScript DiceCoefficient."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
MAX_STRING_LENGTH = 128
MAX_INPUT_LENGTH = 2 + 2 * MAX_STRING_LENGTH
MIN_CODEPOINT = 32
MAX_CODEPOINT = 126


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT
    length_a, length_b = values[:2]
    if (not 0 <= length_a <= MAX_STRING_LENGTH or not 0 <= length_b <= MAX_STRING_LENGTH
            or len(values) != 2 + length_a + length_b):
        return INVALID_RESULT
    codes_a = values[2:2 + length_a]
    codes_b = values[2 + length_a:]
    if any(not MIN_CODEPOINT <= code <= MAX_CODEPOINT for code in (*codes_a, *codes_b)):
        return INVALID_RESULT
    string_a = bytes(codes_a)
    string_b = bytes(codes_b)

    if string_a == string_b:
        return 1.0
    if length_a < 2 or length_b < 2:
        return 0.0

    bigrams_a = {string_a[index:index + 2] for index in range(length_a - 1)}
    common = sum(string_b[index:index + 2] in bigrams_a for index in range(length_b - 1))
    dice = (2 * common) / (length_a - 1 + length_b - 1)
    return math.floor(dice * 100) / 100
