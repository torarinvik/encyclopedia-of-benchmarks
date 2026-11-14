"""Direct contract reference: validate and build a monotone-chain hull."""

import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False,
                    input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or not 7 <= len(values) <= 66
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    n = values[0]
    if not 3 <= n <= 32 or len(values) != 1 + 2*n:
        return -1, b""
    points = list(zip(values[1::2], values[2::2]))
    if any(not -1000 <= x <= 1000 or not -1000 <= y <= 1000 for x, y in points):
        return -1, b""
    if len(set(points)) != n:
        return -1, b""
    def cross(a, b, c):
        return (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])
    for i in range(n):
        for j in range(i+1, n):
            for k in range(j+1, n):
                if cross(points[i], points[j], points[k]) == 0:
                    return -1, b""
    ordered = sorted(points)
    def half(sequence):
        chain = []
        for point in sequence:
            while len(chain) >= 2 and cross(chain[-2], chain[-1], point) <= 0:
                chain.pop()
            chain.append(point)
        return chain
    hull = half(ordered)[:-1] + half(reversed(ordered))[:-1]
    words = [coordinate for point in hull for coordinate in point]
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
