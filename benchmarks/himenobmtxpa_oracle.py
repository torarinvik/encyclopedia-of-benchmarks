"""Independent oracle for the bounded Himeno weighted-Jacobi Poisson core."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MIN_SIDE = 2
MAX_SIDE = 6
MIN_ITERATIONS = 1
MAX_ITERATIONS = 4
INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = 5
MAX_OUTPUT_ELEMENTS = 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def expected_output(values: Sequence[float]) -> list[float] | None:
    if len(values) != INPUT_LENGTH:
        return None
    if any(not math.isfinite(float(value)) or float(value) != math.trunc(float(value))
           for value in values):
        return None
    nx, ny, nz, iterations = (int(value) for value in values)
    if (not MIN_SIDE <= nx <= MAX_SIDE or not MIN_SIDE <= ny <= MAX_SIDE
            or not MIN_SIDE <= nz <= MAX_SIDE
            or not MIN_ITERATIONS <= iterations <= MAX_ITERATIONS):
        return None

    p = [0.0] * (nx * ny * nz)
    work = [0.0] * len(p)
    denominator = _f32(float((nx - 1) * (nx - 1)))
    for i in range(nx):
        for j in range(ny):
            for k in range(nz):
                q = i * ny * nz + j * nz + k
                p[q] = _f32(_f32(float(i * i)) / denominator)

    a3 = _f32(1.0 / 6.0)
    omega = _f32(0.8)
    gosa = _f32(0.0)
    for _ in range(iterations):
        gosa = _f32(0.0)
        for i in range(1, nx - 1):
            for j in range(1, ny - 1):
                for k in range(1, nz - 1):
                    q = i * ny * nz + j * nz + k
                    s0 = _f32(_f32(p[q + ny * nz] + p[q + nz]) + p[q + 1])
                    s0 = _f32(_f32(_f32(s0 + p[q - ny * nz]) + p[q - nz]) + p[q - 1])
                    ss = _f32(_f32(s0 * a3) - p[q])
                    gosa = _f32(gosa + _f32(ss * ss))
                    work[q] = _f32(p[q] + _f32(omega * ss))
        for i in range(1, nx - 1):
            for j in range(1, ny - 1):
                for k in range(1, nz - 1):
                    q = i * ny * nz + j * nz + k
                    p[q] = work[q]
    return [float(gosa)]
