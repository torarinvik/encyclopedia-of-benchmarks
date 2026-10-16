"""Source contract for checking nondecreasing or nonincreasing arrays."""
from __future__ import annotations

MAX_INPUT_LENGTH = 256
MIN_VALUE = -1_000_000_000
MAX_VALUE = 1_000_000_000
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if len(values) > MAX_INPUT_LENGTH or any(x < MIN_VALUE or x > MAX_VALUE for x in values):
        return INVALID_RESULT
    increasing = all(values[i] <= values[i + 1] for i in range(len(values) - 1))
    decreasing = all(values[i] >= values[i + 1] for i in range(len(values) - 1))
    return int(increasing or decreasing)
