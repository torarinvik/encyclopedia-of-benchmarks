"""Independent reference for the bounded eight-kernel FLOPS workload."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1.0e300
MIN_STEPS = 2
MAX_STEPS = 128
MAX_INPUT_LENGTH = 3

# Published double-precision polynomial coefficients used by the pinned
# benchmark. The oracle evaluates each polynomial in the source's stated
# Horner order, independently of the language ports.
A = (
    1.0,
    -0.1666666666671334,
    0.833333333809067e-2,
    0.198412715551283e-3,
    0.27557589750762e-5,
    0.2507059876207e-7,
    0.164105986683e-9,
)
B = (
    1.0,
    -0.4999999999982,
    0.4166666664651e-1,
    -0.1388888805755e-2,
    0.24801428034e-4,
    -0.2754213324e-6,
    0.20189405e-8,
)
D1, D2, D3 = 0.3999999946405e-1, 0.96e-3, 0.1233153e-5
E2, E3 = 0.48e-3, 0.411051e-6


def _horner_sin_legacy(w: float) -> float:
    """The source's A-polynomial evaluation for modules 5, 6, and 8."""
    value = A[6]
    for coefficient in (A[5], A[4], A[3], A[2], A[1], 1.0):
        value = value * w + coefficient
    return value


def _horner_sin_alternating(w: float) -> float:
    """The sign-adjusted A-polynomial used by modules 3 and 4."""
    value = A[6]
    for coefficient in (-A[5], A[4], -A[3], A[2], A[1], 1.0):
        value = value * w + coefficient
    return value


def _horner_cos(w: float) -> float:
    value = B[6]
    for coefficient in (B[5], B[4], B[3], B[2], B[1], 1.0):
        value = value * w + coefficient
    return value


def _module_1(steps: int) -> float:
    # Original module 1 doubles its interval count before the integration.
    n = 2 * steps
    dx = 1.0 / n
    total = 0.0
    v = 0.0
    for _ in range(1, n):
        v += 1.0
        u = v * dx
        numerator = D1 + u * (D2 + u * D3)
        denominator = 1.0 + u * (D1 + u * (E2 + u * E3))
        total += numerator / denominator
    endpoint = (D1 + D2 + D3) / (1.0 + D1 + E2 + E3)
    approximation = dx * (endpoint + D1 + 2.0 * total) / 2.0
    return 1.0 / approximation


def _module_2(steps: int) -> float:
    # Keep the source's two alternating loops and its final pi correction.
    s = -5.0
    partial = -1.0
    for _ in range(steps):
        s = -s
        partial += s
    scale = float(steps)
    u = partial
    v = 0.0
    w = 0.0
    x = 0.0
    for _ in range(steps):
        s = -s
        partial += s
        u += 2.0
        x = x + (s - u)
        v = v - s * u
        w = w + s / u
    partial = 4.0 * w / 5.0
    estimate = partial + 5.0 / v
    return estimate - 31.25 / (v * v * v)


def _module_3(steps: int) -> float:
    dx = math.pi / (3.0 * steps)
    total = 0.0
    v = 0.0
    for _ in range(1, steps):
        v += 1.0
        u = v * dx
        w = u * u
        total += u * _horner_sin_alternating(w)
    u = math.pi / 3.0
    w = u * u
    endpoint = u * _horner_sin_alternating(w)
    return dx * (endpoint + 2.0 * total) / 2.0


def _module_4(steps: int) -> float:
    dx = math.pi / (3.0 * steps)
    total = 0.0
    for index in range(1, steps):
        u = float(index) * dx
        w = u * u
        total += w * (w * (w * (w * (w * (B[6] * w + B[5]) + B[4]) + B[3]) + B[2]) + B[1]) + 1.0
    u = math.pi / 3.0
    w = u * u
    endpoint = w * (w * (w * (w * (w * (B[6] * w + B[5]) + B[4]) + B[3]) + B[2]) + B[1]) + 1.0
    return dx * (endpoint + 1.0 + 2.0 * total) / 2.0


def _module_5(steps: int) -> float:
    dx = math.pi / (3.0 * steps)
    total = 0.0
    for index in range(1, steps):
        u = float(index) * dx
        w = u * u
        numerator = u * _horner_sin_legacy(w)
        denominator = _horner_cos(w)
        total += numerator / denominator
    u = math.pi / 3.0
    w = u * u
    endpoint = u * _horner_sin_legacy(w) / _horner_cos(w)
    return dx * (endpoint + 2.0 * total) / 2.0


def _module_6(steps: int) -> float:
    dx = math.pi / (4.0 * steps)
    total = 0.0
    for index in range(1, steps):
        u = float(index) * dx
        w = u * u
        sine = u * _horner_sin_legacy(w)
        cosine = _horner_cos(w)
        total += sine * cosine
    u = math.pi / 4.0
    w = u * u
    endpoint = (u * _horner_sin_legacy(w)) * _horner_cos(w)
    return dx * (endpoint + 2.0 * total) / 2.0


def _module_7(steps: int) -> float:
    end = 102.3321513995275
    dx = end / steps
    total = 0.0
    for index in range(1, steps):
        x = float(index) * dx
        square = x * x
        total = total - 1.0 / (x + 1.0) - x / (square + 1.0) - square / (x * square + 1.0)
    x = end
    square = x * x
    endpoint = -1.0 - 1.0 / (x + 1.0) - x / (square + 1.0) - square / (x * square + 1.0)
    return 18.0 * dx * (endpoint + 2.0 * total)


def _module_8(steps: int) -> float:
    dx = math.pi / (3.0 * steps)
    total = 0.0
    for index in range(1, steps):
        u = float(index) * dx
        w = u * u
        cosine = _horner_cos(w)
        integrand = cosine * cosine * u * _horner_sin_legacy(w)
        total += integrand
    u = math.pi / 3.0
    w = u * u
    cosine = _horner_cos(w)
    endpoint = (u * _horner_sin_legacy(w)) * cosine * cosine
    return dx * (endpoint + 2.0 * total) / 2.0


_MODULES = (_module_1, _module_2, _module_3, _module_4, _module_5, _module_6, _module_7, _module_8)


def expected_result(values: Sequence[int] | None) -> float:
    if not isinstance(values, (list, tuple)) or len(values) != 2:
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT
    module, steps = values
    if not 1 <= module <= len(_MODULES) or not MIN_STEPS <= steps <= MAX_STEPS:
        return INVALID_RESULT
    result = _MODULES[module - 1](steps)
    return result if math.isfinite(result) else INVALID_RESULT
