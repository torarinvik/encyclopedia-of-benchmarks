"""Source-backed oracle for the Java stateful complementary filter."""

from __future__ import annotations

MAX_SAMPLES = 32
SCALE = 1_000_000
MAX_SIGNAL_MICRO = 1_000_000
INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the final estimate after a bounded sequence of Java accept calls."""
    if (len(values) < 2
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    coefficient_ppm, sample_count = values[:2]
    if not 1 <= coefficient_ppm < SCALE or not 1 <= sample_count <= MAX_SAMPLES:
        return INVALID_RESULT
    if len(values) != 2 + 3 * sample_count:
        return INVALID_RESULT

    samples = values[2:]
    for index in range(sample_count):
        rate, reference, elapsed = samples[3 * index:3 * index + 3]
        if (not -MAX_SIGNAL_MICRO <= rate <= MAX_SIGNAL_MICRO
                or not -MAX_SIGNAL_MICRO <= reference <= MAX_SIGNAL_MICRO
                or not 1 <= elapsed <= SCALE):
            return INVALID_RESULT

    coefficient = coefficient_ppm / SCALE
    value = 0.0
    for index in range(sample_count):
        rate_micro, reference_micro, elapsed_micro = samples[3 * index:3 * index + 3]
        rate = rate_micro / SCALE
        reference = reference_micro / SCALE
        elapsed = elapsed_micro / SCALE
        if index == 0:
            value = reference
        else:
            value = coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference
    return value
