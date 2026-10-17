"""Independent float32-step oracle for the bounded pinned C PID controller."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MIN_INPUT_LENGTH = 5
MAX_INPUT_LENGTH = 64
MIN_ERROR_COUNT = 1
MAX_ERROR_COUNT = 60
MIN_GAIN = -1.0
MAX_GAIN = 1.0
MIN_DT = 0.01
MAX_DT = 1.0
MIN_ERROR = -1.0
MAX_ERROR = 1.0


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def expected_output(values: Sequence[float]) -> list[float] | None:
    """Return the widened per-step results, or None for invalid input."""
    if (not isinstance(values, (list, tuple))
            or not MIN_INPUT_LENGTH <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return None

    kp64, ki64, kd64, dt64 = (float(value) for value in values[:4])
    errors64 = [float(value) for value in values[4:]]
    if (not MIN_ERROR_COUNT <= len(errors64) <= MAX_ERROR_COUNT
            or any(not MIN_GAIN <= gain <= MAX_GAIN for gain in (kp64, ki64, kd64))
            or (dt64 != 0.0 and not MIN_DT <= dt64 <= MAX_DT)
            or any(not MIN_ERROR <= error <= MAX_ERROR for error in errors64)):
        return None

    kp, ki, kd, dt = (_f32(value) for value in (kp64, ki64, kd64, dt64))
    errors = [_f32(value) for value in errors64]
    integral = _f32(0.0)
    last_error = _f32(0.0)
    results: list[float] = []

    for error in errors:
        proportional = _f32(error * kp)
        integral_step = _f32(error * dt)
        integral_step = _f32(integral_step * ki)
        integral = _f32(integral + integral_step)
        if dt == 0.0:
            derivative = _f32(0.0)
        else:
            difference = _f32(error - last_error)
            rate = _f32(difference / dt)
            derivative = _f32(rate * kd)
        last_error = error
        partial = _f32(proportional + integral)
        result = _f32(partial + derivative)
        results.append(float(result))
    return results
