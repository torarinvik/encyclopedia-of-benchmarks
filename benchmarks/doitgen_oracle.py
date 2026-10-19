"""Reference model for the bounded PolyBench/C Doitgen kernel."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_DIMENSION = 16
MAX_INPUT_LENGTH = 3


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    nr, nq, np = values
    if not all(1 <= dimension <= MAX_DIMENSION for dimension in (nr, nq, np)):
        return INVALID_RESULT

    a = [0.0] * (nr * nq * np)
    c4 = [0.0] * (np * np)
    sums = [0.0] * np
    for r in range(nr):
        for q in range(nq):
            for p in range(np):
                a[(r * nq + q) * np + p] = ((r * q + p) % np) / np
    for i in range(np):
        for j in range(np):
            c4[i * np + j] = (i * j % np) / np

    for r in range(nr):
        for q in range(nq):
            for p in range(np):
                sums[p] = 0.0
                for s in range(np):
                    sums[p] += a[(r * nq + q) * np + s] * c4[s * np + p]
            for p in range(np):
                a[(r * nq + q) * np + p] = sums[p]

    checksum = 0.0
    for r in range(nr):
        for q in range(nq):
            for p in range(np):
                checksum += a[(r * nq + q) * np + p]
    return checksum
