"""Reference model for the bounded PolyBench/C 2mm kernel."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_DIMENSION = 16
MAX_INPUT_LENGTH = 4


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    ni, nj, nk, nl = values
    if not all(1 <= dimension <= MAX_DIMENSION for dimension in (ni, nj, nk, nl)):
        return INVALID_RESULT

    alpha, beta = 1.5, 1.2
    a = [0.0] * (ni * nk)
    b = [0.0] * (nk * nj)
    c = [0.0] * (nj * nl)
    d = [0.0] * (ni * nl)
    tmp = [0.0] * (ni * nj)
    for i in range(ni):
        for k in range(nk):
            a[i * nk + k] = ((i * k + 1) % ni) / ni
    for k in range(nk):
        for j in range(nj):
            b[k * nj + j] = (k * (j + 1) % nj) / nj
    for j in range(nj):
        for l in range(nl):
            c[j * nl + l] = ((j * (l + 3) + 1) % nl) / nl
    for i in range(ni):
        for l in range(nl):
            d[i * nl + l] = (i * (l + 2) % nk) / nk

    for i in range(ni):
        for j in range(nj):
            tmp[i * nj + j] = 0.0
            for k in range(nk):
                tmp[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j]
    for i in range(ni):
        for l in range(nl):
            d[i * nl + l] *= beta
            for j in range(nj):
                d[i * nl + l] += tmp[i * nj + j] * c[j * nl + l]

    checksum = 0.0
    for i in range(ni):
        for l in range(nl):
            checksum += d[i * nl + l]
    return checksum
