"""Independent bounded oracle for the Haskell complementary-filter trace."""

from __future__ import annotations

SCALE = 1_000_000
MAX_SAMPLES = 32
MAX_SIGNAL_MICRO = 1_000_000
INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the selected entry in the source's scanl output trace."""
    if (not isinstance(values, (list, tuple)) or len(values) < 6
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    alpha_ppm, delta_t_micro, count, output_index = values[:4]
    if (not 0 <= alpha_ppm <= SCALE
            or not 0 <= delta_t_micro <= SCALE
            or not 1 <= count <= MAX_SAMPLES
            or len(values) != 4 + 2 * count
            or not 0 <= output_index <= count):
        return INVALID_RESULT

    rates = values[4:4 + count]
    accelerometer_angles = values[4 + count:]
    if any(not -MAX_SIGNAL_MICRO <= value <= MAX_SIGNAL_MICRO for value in rates + accelerometer_angles):
        return INVALID_RESULT

    alpha = alpha_ppm / SCALE
    delta_t = delta_t_micro / SCALE
    theta = accelerometer_angles[0] / SCALE
    for index in range(output_index):
        rate = rates[index] / SCALE
        reference = accelerometer_angles[index] / SCALE
        theta = alpha * (theta + rate * delta_t) + (1.0 - alpha) * reference
    return theta
