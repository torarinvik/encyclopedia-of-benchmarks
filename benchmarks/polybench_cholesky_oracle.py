"""Reference model for the bounded PolyBench/C Cholesky kernel."""

from __future__ import annotations

from math import sqrt

INVALID_RESULT = -1e300
MAX_DIMENSION = 64
MAX_INPUT_LENGTH = 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or type(values[0]) is not int or not 1 <= values[0] <= MAX_DIMENSION):
        return INVALID_RESULT
    n = values[0]

    # The C initializer's (-j % n) uses signed remainder. Since 0 <= j < n,
    # it equals -j; the diagonal is reset to one after this loop.
    initial = [0.0] * (n * n)
    for i in range(n):
        for j in range(i + 1):
            initial[i * n + j] = float(-(j % n)) / float(n) + 1.0
        for j in range(i + 1, n):
            initial[i * n + j] = 0.0
        initial[i * n + i] = 1.0

    product = [0.0] * (n * n)
    for t in range(n):
        for r in range(n):
            for s in range(n):
                product[r * n + s] = (
                    product[r * n + s] + initial[r * n + t] * initial[s * n + t]
                )
    a = product

    for i in range(n):
        for j in range(i):
            for k in range(j):
                a[i * n + j] = a[i * n + j] - a[i * n + k] * a[j * n + k]
            a[i * n + j] = a[i * n + j] / a[j * n + j]
        for k in range(i):
            a[i * n + i] = a[i * n + i] - a[i * n + k] * a[i * n + k]
        a[i * n + i] = sqrt(a[i * n + i])

    result = 0.0
    for i in range(n):
        for j in range(i + 1):
            result += a[i * n + j]
    return result
