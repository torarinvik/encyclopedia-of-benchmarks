"""Bounded source-order oracle for ANSIbench's Whetstone operation core."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_PASSES = 3
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1e300


def _p3(x: float, y: float) -> float:
    x1 = x
    y1 = y
    x1 = 0.499975 * (x1 + y1)
    y1 = 0.499975 * (x1 + y1)
    return (x1 + y1) / 2.0


def _pa(e: list[float]) -> None:
    j = 0
    while True:
        e[1] = (e[1] + e[2] + e[3] - e[4]) * 0.499975
        e[2] = (e[1] + e[2] - e[3] + e[4]) * 0.499975
        e[3] = (e[1] - e[2] + e[3] + e[4]) * 0.499975
        e[4] = (-e[1] + e[2] + e[3] + e[4]) / 2.0
        j += 1
        if j >= 6:
            break


def _one_pass() -> float:
    t, t1, t2 = 0.499975, 0.50025, 2.0
    checksum = 0.0
    projection_index = 1

    def include(*items: float) -> None:
        nonlocal checksum, projection_index
        for item in items:
            checksum += float(projection_index) * item
            projection_index += 1

    # Module 1: N1 = 0 when LOOP = 1.
    x1, x2, x3, x4 = 1.0, -1.0, -1.0, -1.0
    include(x1, x2, x3, x4)

    # Module 2: N2 = 12 * LOOP.
    e = [0.0, 1.0, -1.0, -1.0, -1.0]
    for _ in range(12):
        e[1] = (e[1] + e[2] + e[3] - e[4]) * t
        e[2] = (e[1] + e[2] - e[3] + e[4]) * t
        e[3] = (e[1] - e[2] + e[3] + e[4]) * t
        e[4] = (-e[1] + e[2] + e[3] + e[4]) * t
    include(e[1], e[2], e[3], e[4])

    # Module 3: N3 = 14 * LOOP calls to PA; each PA performs six rounds.
    for _ in range(14):
        _pa(e)
    include(e[1], e[2], e[3], e[4])

    # Module 4: conditional jumps, N4 = 345 * LOOP.
    j = 1
    for _ in range(345):
        j = 2 if j == 1 else 3
        j = 0 if j > 2 else 1
        j = 1 if j < 1 else 0
    include(float(j))

    # Module 6: integer arithmetic, N6 = 210 * LOOP.
    j, k, ell = 1, 2, 3
    for _ in range(210):
        j = j * (k - j) * (ell - k)
        k = ell * k - (ell - j) * k
        ell = (ell - k) * (k + j)
        e[ell - 1] = float(j + k + ell)
        e[k - 1] = float(j * k * ell)
    include(float(j), float(k), float(ell), e[1], e[2], e[3], e[4])

    # Module 7: trigonometric functions, N7 = 32 * LOOP.
    x, y = 0.5, 0.5
    for _ in range(32):
        x = t * math.atan(t2 * math.sin(x) * math.cos(x) /
                          (math.cos(x + y) + math.cos(x - y) - 1.0))
        y = t * math.atan(t2 * math.sin(y) * math.cos(y) /
                          (math.cos(x + y) + math.cos(x - y) - 1.0))
    include(x, y)

    # Module 8: procedure calls, N8 = 899 * LOOP.
    x = y = z = 1.0
    for _ in range(899):
        z = _p3(x, y)
    include(x, y, z)

    # Module 9: array references, N9 = 616 * LOOP.
    j, k, ell = 1, 2, 3
    e[1], e[2], e[3] = 1.0, 2.0, 3.0
    for _ in range(616):
        e[j] = e[k]
        e[k] = e[ell]
        e[ell] = e[j]
    include(float(j), float(k), float(ell), e[1], e[2], e[3], e[4])

    # Module 10: N10 = 0 when LOOP = 1.
    j, k = 2, 3
    include(float(j), float(k))

    # Module 11: standard functions, N11 = 93 * LOOP.
    x = 0.75
    for _ in range(93):
        x = math.sqrt(math.exp(math.log(x) / t1))
    include(x)
    return checksum


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values):
        return INVALID_RESULT
    if len(values) != 1 or not 1 <= values[0] <= MAX_PASSES:
        return INVALID_RESULT
    total = 0.0
    for pass_index in range(values[0]):
        total += float(pass_index + 1) * _one_pass()
    return total if math.isfinite(total) else INVALID_RESULT


oracle = expected_result
