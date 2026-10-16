"""Oracle for the pinned Python 32-bit DJB2 hash on a bounded code-point domain."""

from __future__ import annotations

MAX_STRING_LENGTH = 64
MAX_INPUT_LENGTH = MAX_STRING_LENGTH + 1  # admit a one-over-bound input
INVALID_RESULT = -1
UINT32_MASK = (1 << 32) - 1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    if len(values) > MAX_STRING_LENGTH or any(not 0 <= value <= 255 for value in values):
        return INVALID_RESULT

    hash_value = 5381
    for code_point in values:
        hash_value = (hash_value * 33 + code_point) & UINT32_MASK
    return hash_value
