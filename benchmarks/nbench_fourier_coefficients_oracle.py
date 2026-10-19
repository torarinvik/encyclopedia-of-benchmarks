"""Bounded source-order oracle for NBench's Fourier coefficient kernel."""
from __future__ import annotations
import math
from typing import Sequence

MAX_N = 16
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1e300
STEPS = 200


def _term(x: float, omega: float, select: int) -> float:
    base = math.pow(x + 1.0, x)
    if select == 0: return base
    if select == 1: return base * math.cos(omega * x)
    return base * math.sin(omega * x)


def _integrate(omega: float, select: int) -> float:
    x = 0.0
    dx = (2.0 - 0.0) / float(STEPS)
    value = _term(0.0, omega, select) / 2.0
    steps = STEPS
    if steps != 1:
        steps -= 1
        while True:
            steps -= 1
            if steps == 0: break
            x += dx
            value += _term(x, omega, select)
    return (value + _term(2.0, omega, select) / 2.0) * dx


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values):
        return INVALID_RESULT
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1:
        return INVALID_RESULT
    a = [0.0] * n
    b = [0.0] * n
    a[0] = _integrate(0.0, 0) / 2.0
    for i in range(1, n):
        omega = 3.1415926535897932 * float(i)
        a[i] = _integrate(omega, 1)
        b[i] = _integrate(omega, 2)
    checksum = 0.0
    for i in range(n): checksum += float(i + 1) * a[i]
    for i in range(1, n): checksum += float(i) * b[i]
    return checksum if math.isfinite(checksum) else INVALID_RESULT
