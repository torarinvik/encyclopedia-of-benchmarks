"""Independent bounded oracle for the apparent-power benchmark."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
MAX_MAGNITUDE = 1_000
MIN_ANGLE_DEGREES = -360
MAX_ANGLE_DEGREES = 360


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return one component of the source's complex phasor product."""
    if (not isinstance(values, (list, tuple)) or len(values) != 5
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    component, voltage, current, voltage_angle, current_angle = values
    if (component not in (0, 1)
            or not 0 <= voltage <= MAX_MAGNITUDE
            or not 0 <= current <= MAX_MAGNITUDE
            or not MIN_ANGLE_DEGREES <= voltage_angle <= MAX_ANGLE_DEGREES
            or not MIN_ANGLE_DEGREES <= current_angle <= MAX_ANGLE_DEGREES):
        return INVALID_RESULT

    voltage_radians = math.radians(voltage_angle)
    current_radians = math.radians(current_angle)
    voltage_real = voltage * math.cos(voltage_radians)
    voltage_imag = voltage * math.sin(voltage_radians)
    current_real = current * math.cos(current_radians)
    current_imag = current * math.sin(current_radians)
    real = voltage_real * current_real - voltage_imag * current_imag
    imag = voltage_real * current_imag + voltage_imag * current_real
    return real if component == 0 else imag
