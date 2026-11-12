"""Reference floor-sum oracle using a recursive Euclidean reciprocity step."""
from __future__ import annotations

MAX_N = 1_000_000_000
MAX_M = 1_000_000_000
MAX_DIRECT_N = 4096
INVALID_RESULT = -1


def _floor_sum_recursive(n: int, m: int, a: int, b: int) -> int:
    """Sum floor((a*i+b)/m) for 0 <= i < n, assuming nonnegative inputs."""
    answer = 0
    if a >= m:
        quotient, a = divmod(a, m)
        left, right = n, n - 1
        if left % 2 == 0:
            left //= 2
        else:
            right //= 2
        answer += left * right * quotient
    if b >= m:
        quotient, b = divmod(b, m)
        answer += n * quotient
    height, remainder = divmod(a * n + b, m)
    if height == 0:
        return answer
    return answer + _floor_sum_recursive(height, a, m, remainder)


def expected_result(values: list[int], algorithm: str = "sum_of_floor_of_linear") -> int:
    if (algorithm != "sum_of_floor_of_linear" or not isinstance(values, list)
            or len(values) != 4
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    n, m, a, b = values
    if (not 1 <= n <= MAX_N or not 1 <= m <= MAX_M
            or not 0 <= a < m or not 0 <= b < m):
        return INVALID_RESULT
    if n <= MAX_DIRECT_N:
        return sum((a * index + b) // m for index in range(n))
    return _floor_sum_recursive(n, m, a, b)
