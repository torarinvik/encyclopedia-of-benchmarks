"""Oracle for the bounded pinned Python Weddle-rule quadrature."""

from __future__ import annotations

MAX_PANELS = 64
MAX_STEP_NANOUNITS = 1_000_000_000
MAX_SAMPLE_MICRO = 1_000_000
MAX_INPUT_LENGTH = 6 * MAX_PANELS + 3
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) < 9
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    panels, step_nanounits = values[:2]
    if not 1 <= panels <= MAX_PANELS or len(values) != 6 * panels + 3:
        return INVALID_RESULT
    if not -MAX_STEP_NANOUNITS <= step_nanounits <= MAX_STEP_NANOUNITS:
        return INVALID_RESULT
    samples = values[2:]
    if any(not -MAX_SAMPLE_MICRO <= sample <= MAX_SAMPLE_MICRO for sample in samples):
        return INVALID_RESULT

    weighted_sum = 0.0
    for index in range(1, len(samples) - 1):
        if index % 2 == 0 and index % 3 != 0:
            weight = 1
        elif index % 2 != 0 and index % 3 != 0:
            weight = 5
        elif index % 6 == 0:
            weight = 2
        else:
            weight = 6
        weighted_sum += weight * (samples[index] / 1_000_000.0)

    step_size = step_nanounits / 1_000_000_000.0
    return 0.3 * step_size * (
        weighted_sum + samples[0] / 1_000_000.0 + samples[-1] / 1_000_000.0
    )
