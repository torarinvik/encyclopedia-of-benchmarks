"""Independent oracle for a four-sample, fixed-parameter Fresnel transfer slice."""
from __future__ import annotations

import math

MAX_INPUT_LENGTH = 12
PHYSICAL = (4.0, 1.0, 1.0, 16.0)


def expected_result(values: list[float]) -> list[float] | None:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(x) not in (int, float) or not math.isfinite(float(x)) for x in values)):
        return None
    if tuple(float(x) for x in values[:4]) != PHYSICAL:
        return None
    if any(abs(float(x)) > 100.0 for x in values[4:]):
        return None
    real = [float(x) for x in values[4:8]]
    imag = [float(x) for x in values[8:12]]
    shifted_real = [real[2], real[3], real[0], real[1]]
    shifted_imag = [imag[2], imag[3], imag[0], imag[1]]
    fr, fi = [0.0] * 4, [0.0] * 4
    for k in range(4):
        for j in range(4):
            angle = -math.pi * k * j / 2.0
            c, s = math.cos(angle), math.sin(angle)
            fr[k] += shifted_real[j] * c - shifted_imag[j] * s
            fi[k] += shifted_real[j] * s + shifted_imag[j] * c
    # At the fixed parameters, exp(-i*pi*16*f^2) is [1,-1,1,-1].
    for k in range(4):
        if k & 1:
            fr[k] = -fr[k]
            fi[k] = -fi[k]
    zr, zi = [0.0] * 4, [0.0] * 4
    for j in range(4):
        for k in range(4):
            angle = math.pi * k * j / 2.0
            c, s = math.cos(angle), math.sin(angle)
            zr[j] += (fr[k] * c - fi[k] * s) / 4.0
            zi[j] += (fr[k] * s + fi[k] * c) / 4.0
    return [zr[2], zr[3], zr[0], zr[1], zi[2], zi[3], zi[0], zi[1]]
