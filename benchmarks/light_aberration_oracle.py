"""Source-ordered oracle for the bounded Python light-aberration function."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    theta_microrad, beta_ppm = values
    if not -3_141_592 <= theta_microrad <= 3_141_592 or not 0 <= beta_ppm <= 999_999:
        return INVALID_RESULT

    angle_rest = theta_microrad / 1_000_000
    velocity_over_c = beta_ppm / 1_000_000
    factor = math.sqrt((1 - velocity_over_c) / (1 + velocity_over_c))
    angle_ab = 2 * math.atan(factor * math.tan(angle_rest / 2))
    scaled_fraction = angle_ab * 100_000 - math.floor(angle_ab * 100_000)
    if abs(scaled_fraction - 0.5) <= 1e-7:
        return INVALID_RESULT
    return round(angle_ab, 5)
