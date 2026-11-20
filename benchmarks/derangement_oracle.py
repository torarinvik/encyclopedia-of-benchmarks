"""Independent inclusion-exclusion model for the bounded derangement contract."""
import math


def expected_result(n):
    if not 0 <= n <= 20:
        return -1
    if n == 0:
        return 0
    factorial = math.factorial(n)
    return sum((-1 if k % 2 else 1) * (factorial // math.factorial(k))
               for k in range(n+1))
