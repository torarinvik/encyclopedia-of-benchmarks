"""Independent bounded oracle for Java's one-step simple-pendulum RK4."""

from __future__ import annotations

import math

SCALE = 1_000_000.0
INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 64
MAX_OUTPUT_ELEMENTS = 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2

_RANGES = (
    (10_000.0, 100_000_000.0),       # length in metres
    (100_000.0, 20_000_000.0),       # gravity in m/s^2
    (-3_141_593.0, 3_141_593.0),     # theta in radians
    (-100_000_000.0, 100_000_000.0), # omega in radians/s
    (1.0, 100_000.0),                # dt in seconds
)


def _valid_inputs(values: object) -> tuple[float, float, float, float, float] | None:
    if not isinstance(values, (list, tuple)) or len(values) != INPUT_LENGTH:
        return None

    scaled: list[float] = []
    for value, (minimum, maximum) in zip(values, _RANGES):
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(number) or not number.is_integer():
            return None
        if number < minimum or number > maximum:
            return None
        scaled.append(number / SCALE)
    return tuple(scaled)  # type: ignore[return-value]


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    """Return [theta_next, omega_next], or None for an invalid packed state."""
    decoded = _valid_inputs(values)
    if decoded is None:
        return None
    length, gravity, theta, omega, dt = decoded
    acceleration_scale = gravity / length

    # Evaluate the same classical four-stage RK method as the pinned Java source,
    # keeping its [theta, omega] component and summation order explicit.
    k1_theta = omega
    k1_omega = -acceleration_scale * math.sin(theta)

    k2_theta = omega + 0.5 * dt * k1_omega
    k2_omega = -acceleration_scale * math.sin(theta + 0.5 * dt * k1_theta)

    k3_theta = omega + 0.5 * dt * k2_omega
    k3_omega = -acceleration_scale * math.sin(theta + 0.5 * dt * k2_theta)

    k4_theta = omega + dt * k3_omega
    k4_omega = -acceleration_scale * math.sin(theta + dt * k3_theta)

    theta_next = theta + dt / 6.0 * (
        k1_theta + 2.0 * k2_theta + 2.0 * k3_theta + k4_theta
    )
    omega_next = omega + dt / 6.0 * (
        k1_omega + 2.0 * k2_omega + 2.0 * k3_omega + k4_omega
    )
    return [theta_next, omega_next]
