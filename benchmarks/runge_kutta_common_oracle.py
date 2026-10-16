"""Shared exact-step binary64 oracle for the three bounded Runge-Kutta packages."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
SCALE = 1_000_000.0
MAX_INPUT_LENGTH = 5


def _f(function_id: int, x: float, y: float) -> float:
    if function_id == 0:
        return y
    if function_id == 1:
        return x
    if function_id == 2:
        return x + y
    if function_id == 3:
        return (x - y) / 2
    return 1 + y * y


def _finite(*values: float) -> bool:
    return all(math.isfinite(value) for value in values)


def _step_rk4(function_id: int, x: float, y: float, h: float) -> tuple[float, bool]:
    k1 = _f(function_id, x, y)
    k2 = _f(function_id, x + 0.5 * h, y + 0.5 * h * k1)
    k3 = _f(function_id, x + 0.5 * h, y + 0.5 * h * k2)
    k4 = _f(function_id, x + h, y + h * k3)
    result = y + (1 / 6) * h * (k1 + 2 * k2 + 2 * k3 + k4)
    return result, _finite(k1, k2, k3, k4, result)


def _step_fehlberg(function_id: int, x: float, y: float, h: float) -> tuple[float, bool]:
    k1 = h * _f(function_id, x, y)
    k2 = h * _f(function_id, x + h / 4, y + k1 / 4)
    k3 = h * _f(function_id, x + (3 / 8) * h, y + (3 / 32) * k1 + (9 / 32) * k2)
    k4 = h * _f(function_id, x + (12 / 13) * h,
                y + (1932 / 2197) * k1 - (7200 / 2197) * k2 + (7296 / 2197) * k3)
    k5 = h * _f(function_id, x + h,
                y + (439 / 216) * k1 - 8 * k2 + (3680 / 513) * k3 - (845 / 4104) * k4)
    k6 = h * _f(function_id, x + h / 2,
                y - (8 / 27) * k1 + 2 * k2 - (3544 / 2565) * k3
                + (1859 / 4104) * k4 - (11 / 40) * k5)
    result = y + (16 / 135) * k1 + (6656 / 12825) * k3 + (28561 / 56430) * k4 - (9 / 50) * k5 + (2 / 55) * k6
    return result, _finite(k1, k2, k3, k4, k5, k6, result)


def _step_gill(function_id: int, x: float, y: float, h: float) -> tuple[float, bool]:
    root2 = math.sqrt(2)
    k1 = h * _f(function_id, x, y)
    k2 = h * _f(function_id, x + h / 2, y + k1 / 2)
    k3 = h * _f(function_id, x + h / 2,
                y + (-0.5 + 1 / root2) * k1 + (1 - 1 / root2) * k2)
    k4 = h * _f(function_id, x + h, y - (1 / root2) * k2 + (1 + 1 / root2) * k3)
    result = y + (k1 + (2 - root2) * k2 + (2 + root2) * k3 + k4) / 6
    return result, _finite(k1, k2, k3, k4, result)


def expected_result_for(values: list[int] | tuple[int, ...], method: str) -> float:
    if method not in {"rk4", "fehlberg45", "gill"}:
        raise ValueError("unknown Runge-Kutta method")
    if not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT
    function_id, y0_micro, x0_micro, h_micro, x_end_micro = values
    if not 0 <= function_id <= 4:
        return INVALID_RESULT
    if any(not -1_000_000 <= value <= 1_000_000 for value in (y0_micro, x0_micro, x_end_micro)):
        return INVALID_RESULT
    if not 10_000 <= h_micro <= 250_000 or x_end_micro <= x0_micro:
        return INVALID_RESULT
    y0, x0, h, x_end = (value / SCALE for value in (y0_micro, x0_micro, h_micro, x_end_micro))
    if function_id == 4 and (x0 < 0.0 or y0 > 0.0):
        return INVALID_RESULT
    ratio = (x_end - x0) / h
    steps = math.ceil(ratio) if method == "rk4" else int(ratio)
    if steps < 1 or steps > 64:
        return INVALID_RESULT
    if method != "rk4" and steps == 0:
        return INVALID_RESULT
    y = y0
    x = x0
    step = _step_rk4 if method == "rk4" else _step_fehlberg if method == "fehlberg45" else _step_gill
    for _ in range(steps):
        y, finite = step(function_id, x, y, h)
        if not finite:
            return INVALID_RESULT
        x += h
        if not math.isfinite(x):
            return INVALID_RESULT
    return y if math.isfinite(y) else INVALID_RESULT
