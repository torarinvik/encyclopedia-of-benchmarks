"""Reference model for the bounded PolyBench/C GEMVER kernel."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_DIMENSION = 64
MAX_INPUT_LENGTH = 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    (n,) = values
    if not 1 <= n <= MAX_DIMENSION:
        return INVALID_RESULT

    alpha, beta = 1.5, 1.2
    a = [0.0] * (n * n)
    u1, v1, u2, v2 = ([0.0] * n for _ in range(4))
    w, x, y, z = ([0.0] * n for _ in range(4))
    fn = float(n)
    for i in range(n):
        u1[i] = float(i)
        u2[i] = ((i + 1) / fn) / 2.0
        v1[i] = ((i + 1) / fn) / 4.0
        v2[i] = ((i + 1) / fn) / 6.0
        y[i] = ((i + 1) / fn) / 8.0
        z[i] = ((i + 1) / fn) / 9.0
        for j in range(n):
            a[i * n + j] = ((i * j) % n) / fn

    # Preserve the four ordered source passes, including accumulation order.
    for i in range(n):
        for j in range(n):
            index = i * n + j
            a[index] = a[index] + u1[i] * v1[j] + u2[i] * v2[j]
    for i in range(n):
        for j in range(n):
            x[i] = x[i] + beta * a[j * n + i] * y[j]
    for i in range(n):
        x[i] = x[i] + z[i]
    for i in range(n):
        for j in range(n):
            w[i] = w[i] + alpha * a[i * n + j] * x[j]

    checksum = 0.0
    for i in range(n):
        checksum += w[i]
    return checksum
