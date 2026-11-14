"""Unexecuted rotating-support reference for exact minimum rectangle area."""

from math import gcd
import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 7 <= len(values) <= 34
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    n = values[0]
    if not 3 <= n <= 16 or len(values) != 1+2*n or any(not -100 <= x <= 100 for x in values[1:]):
        return -1, b""
    points = tuple(zip(values[1::2], values[2::2]))
    for i in range(n):
        ax, ay = points[i]
        bx, by = points[(i+1)%n]
        for j, (x, y) in enumerate(points):
            if j != i and j != (i+1)%n and (bx-ax)*(y-ay)-(by-ay)*(x-ax) <= 0:
                return -1, b""
    first_dx = points[1][0]-points[0][0]
    first_dy = points[1][1]-points[0][1]
    first_along = [first_dx*x+first_dy*y for x, y in points]
    first_across = [first_dx*y-first_dy*x for x, y in points]
    supports = [max(range(n), key=first_along.__getitem__),
                min(range(n), key=first_along.__getitem__),
                max(range(n), key=first_across.__getitem__)]
    best_numerator, best_denominator = None, 1
    for i in range(n):
        ax, ay = points[i]
        bx, by = points[(i+1)%n]
        dx, dy = bx-ax, by-ay
        def projection(index, axis):
            x, y = points[index]
            return (dx*x+dy*y) if axis != 2 else (dx*y-dy*x)
        for axis in range(3):
            for _ in range(n):
                current = supports[axis]
                following = (current+1)%n
                a, b = projection(current, axis), projection(following, axis)
                if (axis == 1 and b <= a) or (axis != 1 and b >= a):
                    supports[axis] = following
                else:
                    break
        span = projection(supports[0],0)-projection(supports[1],1)
        thickness = projection(supports[2],2)-(dx*ay-dy*ax)
        numerator, denominator = span*thickness, dx*dx+dy*dy
        if best_numerator is None or numerator*best_denominator < best_numerator*denominator:
            best_numerator, best_denominator = numerator, denominator
    divisor = gcd(best_numerator, best_denominator)
    payload = struct.pack("<qq", best_numerator//divisor, best_denominator//divisor)
    if output_is_null or capacity is not None and capacity < 16:
        return -2, b""
    return 16, payload
