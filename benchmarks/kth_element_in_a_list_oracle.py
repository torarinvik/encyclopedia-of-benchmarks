from collections.abc import Sequence
MAX_INPUT_LENGTH = 34
def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1
    n, k = values[0], values[1]
    if not 1 <= n <= 16 or len(values) != n + 2 or not 1 <= k <= n:
        return -1
    if any(not -10000 <= x <= 10000 for x in values[2:]):
        return -1
    return values[k + 1]
