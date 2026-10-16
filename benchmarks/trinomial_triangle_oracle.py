"""Independent iterative-row oracle for bounded trinomial coefficients."""

from __future__ import annotations

MIN_N = 0
MAX_N = 10
MIN_K = -10
MAX_K = 10


def expected_result(n: int, k: int) -> int:
    if (type(n) is not int or type(k) is not int
            or not MIN_N <= n <= MAX_N or not MIN_K <= k <= MAX_K):
        return -1

    row = {0: 1}
    for _ in range(n):
        following: dict[int, int] = {}
        for position, coefficient in row.items():
            for target in (position - 1, position, position + 1):
                following[target] = following.get(target, 0) + coefficient
        row = following
    return row.get(k, 0)
