"""Oracle for TheAlgorithms/Python kelly_criterion."""

from __future__ import annotations

SCALE = 1_000_000
MIN_PROBABILITY_MICRO = 1
MAX_PROBABILITY_MICRO = 999_999
MIN_RATIO_MICRO = 1_000
MAX_RATIO_MICRO = 100_000_000
MAX_INPUT_LENGTH = 3  # admit one extra packed value for malformed-input coverage
INVALID_RESULT = -1e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    probability_micro, ratio_micro = values
    if (not MIN_PROBABILITY_MICRO <= probability_micro <= MAX_PROBABILITY_MICRO
            or not MIN_RATIO_MICRO <= ratio_micro <= MAX_RATIO_MICRO):
        return INVALID_RESULT

    win_probability = probability_micro / SCALE
    win_loss_ratio = ratio_micro / SCALE
    loss_probability = 1.0 - win_probability
    return (win_probability * win_loss_ratio - loss_probability) / win_loss_ratio
