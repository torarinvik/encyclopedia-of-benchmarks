"""Independent oracle for the bounded Java kth-element heap benchmark."""

from collections.abc import Sequence

MAX_N = 256
MAX_INPUT_LENGTH = MAX_N + 3
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
INVALID_RESULT = -(1 << 63)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    mode, n, k = values[:3]
    items = values[3:]
    if mode not in (0, 1) or not 1 <= n <= MAX_N or len(values) != n + 3:
        return INVALID_RESULT
    if not 1 <= k <= n or any(not MIN_VALUE <= value <= MAX_VALUE for value in items):
        return INVALID_RESULT

    ordered = sorted(items, reverse=(mode == 0))
    return ordered[k - 1]
