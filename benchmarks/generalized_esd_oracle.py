"""Oracle for a bounded fixed-alpha Rosner generalized ESD test."""
from __future__ import annotations
import math

INVALID_RESULT = -1
MAX_SAMPLE_SIZE = 8
MAX_ABS_VALUE = 10_000
CRITICAL_005 = (0.0, 0.0, 0.0, 1.1543048513440384, 1.48125,
                1.715037312343363, 1.887145117783933,
                2.0199685076795957, 2.126645087195462)

def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 5
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return INVALID_RESULT
    n, limit = values[:2]
    if not 3 <= n <= MAX_SAMPLE_SIZE or not 1 <= limit <= min(3, n - 2) or len(values) != n + 2:
        return INVALID_RESULT
    sample = list(values[2:])
    if any(abs(x) > MAX_ABS_VALUE for x in sample):
        return INVALID_RESULT
    vals = [float(x) for x in sample]
    indices = list(range(n))
    removed: list[int] = []
    accepted = 0
    remaining = n
    for step in range(1, limit + 1):
        mean = sum(vals[:remaining]) / remaining
        sd = math.sqrt(sum((x - mean) ** 2 for x in vals[:remaining]) / (remaining - 1))
        if sd == 0.0:
            break
        worst = 0
        largest = -1.0
        for i in range(remaining):
            deviation = abs(vals[i] - mean)
            if deviation > largest:
                largest, worst = deviation, i
        statistic = largest / sd
        removed.append(indices[worst])
        if statistic > CRITICAL_005[remaining]:
            accepted = step
        remaining -= 1
        vals[worst], vals[remaining] = vals[remaining], vals[worst]
        indices[worst], indices[remaining] = indices[remaining], indices[worst]
    mask = 0
    for index in sorted(removed[:accepted]):
        mask |= 1 << index
    return mask
