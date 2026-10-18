"""Independent bounded oracle for Java's scalar Kalman filter trace."""

from __future__ import annotations

import math
from collections.abc import Sequence

SCALE = 1_000_000.0
MAX_STEPS = 12
MAX_PARSEABLE_INPUT_LENGTH = 64
MAX_OUTPUT_ELEMENTS = 3 * MAX_STEPS
MIN_STATE_MICRO = -1_000_000_000
MAX_STATE_MICRO = 1_000_000_000
MIN_VARIANCE_MICRO = 0
MAX_VARIANCE_MICRO = 1_000_000_000_000
MIN_MEASUREMENT_NOISE_MICRO = 1


def _decode(values: object) -> tuple[float, float, float, float, list[float]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) not in (int, float) for value in values)
    ):
        return None
    try:
        raw = [float(value) for value in values]
    except (OverflowError, ValueError):
        return None
    if any(not math.isfinite(value) or not value.is_integer() for value in raw):
        return None

    raw_count = raw[4]
    if not 1 <= raw_count <= MAX_STEPS:
        return None
    count = int(raw_count)
    if len(raw) != 5 + count:
        return None

    initial_estimate_micro, initial_covariance_micro, process_noise_micro, measurement_noise_micro = raw[:4]
    if not MIN_STATE_MICRO <= initial_estimate_micro <= MAX_STATE_MICRO:
        return None
    if not MIN_VARIANCE_MICRO <= initial_covariance_micro <= MAX_VARIANCE_MICRO:
        return None
    if not MIN_VARIANCE_MICRO <= process_noise_micro <= MAX_VARIANCE_MICRO:
        return None
    if not MIN_MEASUREMENT_NOISE_MICRO <= measurement_noise_micro <= MAX_VARIANCE_MICRO:
        return None
    measurements_micro = raw[5:]
    if any(not MIN_STATE_MICRO <= value <= MAX_STATE_MICRO for value in measurements_micro):
        return None

    return (
        initial_estimate_micro / SCALE,
        initial_covariance_micro / SCALE,
        process_noise_micro / SCALE,
        measurement_noise_micro / SCALE,
        [value / SCALE for value in measurements_micro],
    )


def expected_result(values: Sequence[int | float]) -> list[float] | None:
    """Return `[x, p, gain]` after every filter cycle, or None if invalid."""
    decoded = _decode(values)
    if decoded is None:
        return None

    estimate, covariance, process_noise, measurement_noise, measurements = decoded
    output: list[float] = []
    for measurement in measurements:
        # Java filter(z): predict() first, then update(z) with default noise.
        estimate += 0.0
        covariance += process_noise
        innovation_variance = covariance + measurement_noise
        gain = covariance / innovation_variance
        estimate += gain * (measurement - estimate)
        covariance = covariance * measurement_noise / innovation_variance
        output.extend((estimate, covariance, gain))
    return output


def expected_output(
    values: Sequence[int | float],
    output_capacity: int = MAX_OUTPUT_ELEMENTS,
    output_is_null: bool = False,
) -> tuple[int, list[float]]:
    expected = expected_result(values)
    if expected is None:
        return -1, []
    if type(output_is_null) is not bool or type(output_capacity) is not int:
        return -1, []
    if output_is_null or output_capacity < len(expected):
        return -2, []
    return len(expected), expected
