"""Sorted-window reference for the bounded minimum-unfairness profile."""

MAX_N = 64
MAX_VALID_INPUT_LENGTH = MAX_N + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = MAX_N * 8
MIN_VALUE = -1_000_000_000
MAX_VALUE = 1_000_000_000
INVALID = -1


def evaluate(packed: list[int]) -> int:
    if len(packed) < 4 or len(packed) > MAX_N + 2:
        return INVALID
    n, k = packed[0], packed[1]
    if not 2 <= n <= MAX_N or not 2 <= k <= n or len(packed) != n + 2:
        return INVALID
    values = list(packed[2:])
    if any(value < MIN_VALUE or value > MAX_VALUE for value in values):
        return INVALID

    values.sort()
    return min(values[first + k - 1] - values[first] for first in range(n - k + 1))
