"""Independent oracle for the bounded maximum circular subarray contract."""

from __future__ import annotations

MAX_VALID_INPUT_LENGTH = 64
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
INVALID_RESULT = -(2**63)


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not MIN_VALUE <= value <= MAX_VALUE
                   for value in values)):
        return INVALID_RESULT

    total = sum(values)
    current_max = max_so_far = values[0]
    current_min = min_so_far = values[0]
    for value in values[1:]:
        current_max = max(current_max + value, value)
        max_so_far = max(max_so_far, current_max)
        current_min = min(current_min + value, value)
        min_so_far = min(min_so_far, current_min)

    if min_so_far == total:
        return max_so_far
    return max(max_so_far, total - min_so_far)
