"""Oracle for the bounded zero-based k-th permutation benchmark."""
from collections.abc import Sequence
MAX_INPUT_LENGTH = 2
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values, (list, tuple)) or len(values) != 2 or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values):
        return INVALID_RESULT
    k, n = values
    if not 2 <= n <= 9 or k < 0:
        return INVALID_RESULT
    fact = 1
    for i in range(2, n + 1): fact *= i
    if k >= fact: return INVALID_RESULT
    remaining = list(range(n))
    rank = k
    code = n
    for block in range(n - 1, 0, -1):
        factorial = 1
        for i in range(2, block + 1): factorial *= i
        index, rank = divmod(rank, factorial)
        code = code * 10 + remaining.pop(index) + 1
    code = code * 10 + remaining[0] + 1
    return code
