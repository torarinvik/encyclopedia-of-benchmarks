"""One-dimensional dynamic-programming oracle for Julia integer partitions."""

MAX_N = 100
I64_MIN = -(1 << 63)

def expected_result(n: int) -> int:
    if type(n) is not int or not 0 <= n <= MAX_N:
        return I64_MIN
    counts = [0] * (n + 1)
    counts[0] = 1
    for part in range(1, n + 1):
        for total in range(part, n + 1):
            counts[total] += counts[total - part]
    return counts[n]
