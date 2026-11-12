"""Independent arbitrary-precision oracle for bounded integer k-th roots."""
from __future__ import annotations

MAX_A = (1 << 63) - 1
MIN_K = 1
MAX_K = 64
MAX_PARSEABLE_INPUT_LENGTH = 3
INVALID_RESULT = -1


def expected_result(values: list[int], algorithm: str = "kth_root_integer") -> int:
    if (algorithm != "kth_root_integer" or not isinstance(values, list)
            or len(values) != 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    number, degree = values
    if not 0 <= number <= MAX_A or not MIN_K <= degree <= MAX_K:
        return INVALID_RESULT

    low, high = 0, number
    while low < high:
        candidate = low + (high - low + 1) // 2
        if pow(candidate, degree) <= number:
            low = candidate
        else:
            high = candidate - 1
    return low
