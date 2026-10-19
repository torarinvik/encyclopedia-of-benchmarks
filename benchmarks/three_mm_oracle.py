"""Reference model for the bounded PolyBench/C 3mm kernel."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_DIMENSION = 16
MAX_INPUT_LENGTH = 5


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    ni, nj, nk, nl, nm = values
    if not all(1 <= dimension <= MAX_DIMENSION
               for dimension in (ni, nj, nk, nl, nm)):
        return INVALID_RESULT

    a = [0.0] * (ni * nk)
    b = [0.0] * (nk * nj)
    c = [0.0] * (nj * nm)
    d = [0.0] * (nm * nl)
    e = [0.0] * (ni * nj)
    f = [0.0] * (nj * nl)
    g = [0.0] * (ni * nl)
    for i in range(ni):
        for k in range(nk):
            a[i * nk + k] = ((i * k + 1) % ni) / (5 * ni)
    for k in range(nk):
        for j in range(nj):
            b[k * nj + j] = ((k * (j + 1) + 2) % nj) / (5 * nj)
    for i in range(nj):
        for j in range(nm):
            c[i * nm + j] = (i * (j + 3) % nl) / (5 * nl)
    for i in range(nm):
        for j in range(nl):
            d[i * nl + j] = ((i * (j + 2) + 2) % nk) / (5 * nk)

    for i in range(ni):
        for j in range(nj):
            e[i * nj + j] = 0.0
            for k in range(nk):
                e[i * nj + j] += a[i * nk + k] * b[k * nj + j]
    for i in range(nj):
        for j in range(nl):
            f[i * nl + j] = 0.0
            for k in range(nm):
                f[i * nl + j] += c[i * nm + k] * d[k * nl + j]
    for i in range(ni):
        for j in range(nl):
            g[i * nl + j] = 0.0
            for k in range(nj):
                g[i * nl + j] += e[i * nj + k] * f[k * nl + j]

    checksum = 0.0
    for i in range(ni):
        for j in range(nl):
            checksum += g[i * nl + j]
    return checksum
