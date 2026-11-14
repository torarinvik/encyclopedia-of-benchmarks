"""Exhaustive reference for the bounded maximum-area triangle profile."""

def expected(values):
    if values is None or not values or not 3 <= values[0] <= 1024:
        return -1
    n = values[0]
    if len(values) != 1 + 2 * n or any(abs(x) > 1000000 for x in values[1:]):
        return -1
    points = list(zip(values[1::2], values[2::2]))

    def cross(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

    for i in range(n):
        for j in range(n):
            if j != i and j != (i + 1) % n and cross(points[i], points[(i + 1) % n], points[j]) <= 0:
                return -1
    best = 0
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                best = max(best, cross(points[i], points[j], points[k]))
    return best
