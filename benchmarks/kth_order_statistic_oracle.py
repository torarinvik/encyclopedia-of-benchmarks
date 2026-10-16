"""Oracle for the bounded unique-value k-th order statistic."""
from collections.abc import Sequence
MAX_INPUT_LENGTH = 65
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values):
        return INVALID_RESULT
    k, *items = values
    if not 1 <= k <= len(items) or len(set(items)) != len(items) or any(not -10000 <= x <= 10000 for x in items):
        return INVALID_RESULT
    return sorted(items)[k - 1]
