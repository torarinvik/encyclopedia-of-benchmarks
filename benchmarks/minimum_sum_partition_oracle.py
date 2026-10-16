"""Independent set-based oracle for minimum-sum partition difference."""

from __future__ import annotations

MAX_VALID_INPUT_LENGTH = 64
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_TOTAL_SUM = 4096
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) > MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not 0 <= value <= MAX_TOTAL_SUM
                   for value in values)):
        return INVALID_RESULT

    total = sum(values)
    if total > MAX_TOTAL_SUM:
        return INVALID_RESULT

    target = total // 2
    reachable = {0}
    for value in values:
        reachable |= {subtotal + value for subtotal in reachable
                      if subtotal + value <= target}
    return total - 2 * max(reachable)
