"""Reference model for the bounded PolyBench/C LUDCMP kernel."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_DIMENSION = 64
MAX_INPUT_LENGTH = 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or type(values[0]) is not int or not 1 <= values[0] <= MAX_DIMENSION):
        return INVALID_RESULT
    n = values[0]
    a = [0.0] * (n * n)
    product = [0.0] * (n * n)
    b = [0.0] * n
    x = [0.0] * n
    y = [0.0] * n

    for i in range(n):
        b[i] = (float(i + 1) / float(n)) / 2.0 + 4.0
    for i in range(n):
        for j in range(i + 1):
            # C's signed remainder gives -j here because j is less than n.
            a[i * n + j] = float(-(j % n)) / float(n) + 1.0
        for j in range(i + 1, n):
            a[i * n + j] = 0.0
        a[i * n + i] = 1.0

    for r in range(n):
        for s in range(n):
            product[r * n + s] = 0.0
    for t in range(n):
        for r in range(n):
            for s in range(n):
                product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t]
    for r in range(n):
        for s in range(n):
            a[r * n + s] = product[r * n + s]

    for i in range(n):
        for j in range(i):
            w = a[i * n + j]
            for k in range(j):
                w = w - a[i * n + k] * a[k * n + j]
            a[i * n + j] = w / a[j * n + j]
        for j in range(i, n):
            w = a[i * n + j]
            for k in range(i):
                w = w - a[i * n + k] * a[k * n + j]
            a[i * n + j] = w

    for i in range(n):
        w = b[i]
        for j in range(i):
            w = w - a[i * n + j] * y[j]
        y[i] = w
    for i in range(n - 1, -1, -1):
        w = y[i]
        for j in range(i + 1, n):
            w = w - a[i * n + j] * x[j]
        x[i] = w / a[i * n + i]

    result = 0.0
    for i in range(n):
        result += x[i]
    return result
