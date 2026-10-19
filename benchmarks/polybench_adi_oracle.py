"""Independent reference for the bounded PolyBench/C ADI kernel."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_DIMENSION = 32
MAX_TSTEPS = 20
MAX_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = MAX_DIMENSION * MAX_DIMENSION * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the final row-major u matrix as little-endian binary64 bytes."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    try:
        length = len(values)
    except (TypeError, OverflowError):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != length):
        return INVALID_RESULT, b""
    if length != MAX_INPUT_LENGTH or any(
        type(value) is not int or not -(1 << 63) <= value < (1 << 63)
        for value in values
    ):
        return INVALID_RESULT, b""

    n, tsteps = values
    if not (1 <= n <= MAX_DIMENSION and 1 <= tsteps <= MAX_TSTEPS):
        return INVALID_RESULT, b""

    u = [0.0] * (n * n)
    v = [0.0] * (n * n)
    p = [0.0] * (n * n)
    q = [0.0] * (n * n)
    for i in range(n):
        for j in range(n):
            u[i * n + j] = float(i + n - j) / float(n)

    dx = 1.0 / float(n)
    dy = 1.0 / float(n)
    dt = 1.0 / float(tsteps)
    b1 = 2.0
    b2 = 1.0
    mul1 = b1 * dt / (dx * dx)
    mul2 = b2 * dt / (dy * dy)
    a = -mul1 / 2.0
    b = 1.0 + mul1
    c = a
    d = -mul2 / 2.0
    e = 1.0 + mul2
    f = d

    for _ in range(1, tsteps + 1):
        # Column sweep. The source indexes each row by j and the column by i.
        for i in range(1, n - 1):
            v[i] = 1.0
            p[i * n] = 0.0
            q[i * n] = v[i]
            for j in range(1, n - 1):
                p[i * n + j] = -c / (a * p[i * n + j - 1] + b)
                q[i * n + j] = (
                    -d * u[j * n + i - 1]
                    + (1.0 + 2.0 * d) * u[j * n + i]
                    - f * u[j * n + i + 1]
                    - a * q[i * n + j - 1]
                ) / (a * p[i * n + j - 1] + b)
            v[(n - 1) * n + i] = 1.0
            j = n - 1
            while j > 1:
                j -= 1
                v[j * n + i] = p[i * n + j] * v[(j + 1) * n + i] + q[i * n + j]

        # Row sweep.
        for i in range(1, n - 1):
            u[i * n] = 1.0
            p[i * n] = 0.0
            q[i * n] = u[i * n]
            for j in range(1, n - 1):
                p[i * n + j] = -f / (d * p[i * n + j - 1] + e)
                q[i * n + j] = (
                    -a * v[(i - 1) * n + j]
                    + (1.0 + 2.0 * a) * v[i * n + j]
                    - c * v[(i + 1) * n + j]
                    - d * q[i * n + j - 1]
                ) / (d * p[i * n + j - 1] + e)
            u[i * n + n - 1] = 1.0
            j = n - 1
            while j > 1:
                j -= 1
                u[i * n + j] = p[i * n + j] * u[i * n + j + 1] + q[i * n + j]

    output_bytes = struct.pack("<" + "d" * (n * n), *u)
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if len(output_bytes) > output_capacity:
            return OUTPUT_ERROR, b""
    if output_is_null:
        return OUTPUT_ERROR, b""
    return len(output_bytes), output_bytes
