"""Reference model for the bounded PolyBench/C GEMM kernel."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_DIMENSION = 64
MAX_INPUT_LENGTH = 3


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    ni, nj, nk = values
    if not all(1 <= dimension <= MAX_DIMENSION for dimension in (ni, nj, nk)):
        return INVALID_RESULT

    alpha = 1.5
    beta = 1.2
    c = [0.0] * (ni * nj)
    a = [0.0] * (ni * nk)
    b = [0.0] * (nk * nj)
    for i in range(ni):
        for j in range(nj):
            c[i * nj + j] = ((i * j + 1) % ni) / ni
    for i in range(ni):
        for k in range(nk):
            a[i * nk + k] = (i * (k + 1) % nk) / nk
    for k in range(nk):
        for j in range(nj):
            b[k * nj + j] = (k * (j + 2) % nj) / nj

    for i in range(ni):
        for j in range(nj):
            c[i * nj + j] *= beta
        for k in range(nk):
            for j in range(nj):
                c[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j]

    checksum = 0.0
    for i in range(ni):
        for j in range(nj):
            checksum += c[i * nj + j]
    return checksum
