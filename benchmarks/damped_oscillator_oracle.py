"""Bounded source-order oracle for the Java damped-oscillator Euler step."""

from __future__ import annotations

import struct

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_BYTES = 16
MAX_OUTPUT_BYTES = OUTPUT_BYTES
MAX_INPUT_LENGTH = 5


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the packed next state, or the invalid-input sentinel."""
    if (not isinstance(values, (list, tuple)) or len(values) != 5
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""

    omega0_q, gamma_q, x_q, v_q, dt_q = values
    if (not 1 <= omega0_q <= 1024 or not 0 <= gamma_q <= 1024
            or not -1024 <= x_q <= 1024 or not -1024 <= v_q <= 1024
            or not 1 <= dt_q <= 1024):
        return INVALID_RESULT, b""

    omega0 = omega0_q / 1024.0
    gamma = gamma_q / 1024.0
    x = x_q / 1024.0
    v = v_q / 1024.0
    dt = dt_q / 1024.0
    acceleration = -2.0 * gamma * v - omega0 * omega0 * x
    x_next = x + dt * v
    v_next = v + dt * acceleration
    return OUTPUT_BYTES, struct.pack("<dd", x_next, v_next)
