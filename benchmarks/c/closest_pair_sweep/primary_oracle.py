"""Unexecuted y-sorted-list sweep reference for the bounded closest pair."""

from bisect import bisect_left, insort
from math import isqrt


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 5 <= len(values) <= 130
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n = values[0]
    if not 2 <= n <= 64 or len(values) != 1+2*n or any(not -1000 <= x <= 1000 for x in values[1:]):
        return -1
    points = sorted(zip(values[1::2], values[2::2]))
    if any(points[i] == points[i-1] for i in range(1,n)):
        return 0
    best = 8_000_001
    active = []
    left = 0
    for x,y in points:
        while left < len(points) and points[left][0] < x and (x-points[left][0])**2 > best:
            old_x, old_y = points[left]
            active.pop(bisect_left(active, (old_y, old_x)))
            left += 1
        radius = isqrt(best)
        start = bisect_left(active, (y-radius, -1001))
        for old_y,old_x in active[start:]:
            if old_y > y+radius:
                break
            best = min(best, (x-old_x)**2 + (y-old_y)**2)
        insort(active, (y,x))
    return best
