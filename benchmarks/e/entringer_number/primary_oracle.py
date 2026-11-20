"""Row-by-row Entringer triangle recurrence."""

from __future__ import annotations

MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3


def entringer_number(values: list[int]) -> int:
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return -1
    n, target = values
    if not (0 <= n <= 12 and 0 <= target <= n):
        return -1
    previous = [1] + [0] * 12
    for row in range(1, n + 1):
        current = [0] * 13
        for col in range(1, row + 1):
            current[col] = current[col - 1] + previous[row - col]
        previous = current
    return previous[target]
