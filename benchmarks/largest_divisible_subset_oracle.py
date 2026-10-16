"""Oracle for the bounded positive-integer largest divisible subset length."""
from collections.abc import Sequence
MAX_INPUT_LENGTH = 64
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(x) is not int or not I64_MIN <= x <= I64_MAX or not 1 <= x <= 50000 for x in values):
        return INVALID_RESULT
    ordered = sorted(values)
    lengths = [1] * len(ordered)
    for i, value in enumerate(ordered):
        for j in range(i):
            if value % ordered[j] == 0:
                lengths[i] = max(lengths[i], lengths[j] + 1)
    return max(lengths, default=0)
