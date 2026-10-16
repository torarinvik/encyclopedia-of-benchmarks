"""Binary64 oracle for the bounded midpoint Euler harmonic oscillator."""

from __future__ import annotations

import struct

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_INPUT_LENGTH = 5
MAX_OUTPUT_BYTES = 16
MAX_STEPS = 8


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the little-endian binary64 pair after fixed midpoint steps."""
    if (not isinstance(values, (list, tuple)) or len(values) != 4
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    steps, dt_quarters, u0, v0 = values
    if not 1 <= steps <= MAX_STEPS or not 1 <= dt_quarters <= 4:
        return -1, b""
    if not -10 <= u0 <= 10 or not -10 <= v0 <= 10:
        return -1, b""
    dt = dt_quarters / 4.0
    half_dt = 0.5 * dt
    u, v = float(u0), float(v0)
    for _ in range(steps):
        midpoint_u = u + half_dt * v
        midpoint_v = v - half_dt * u
        next_u = u + dt * midpoint_v
        next_v = v - dt * midpoint_u
        u, v = next_u, next_v
    return MAX_OUTPUT_BYTES, struct.pack("<dd", u, v)
