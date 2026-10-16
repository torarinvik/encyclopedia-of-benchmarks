"""Oracle for the pinned historical-simulation expected shortfall function."""

from __future__ import annotations

SCALE = 1_000_000
MAX_RETURNS = 64
MAX_PARSED_RETURNS = 65
MAX_SAMPLE = 1_000_000_000
MAX_INPUT_LENGTH = 2 + MAX_PARSED_RETURNS
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    confidence_micro, count = values[:2]
    if not 1 <= confidence_micro < SCALE:
        return INVALID_RESULT
    if not 1 <= count <= MAX_PARSED_RETURNS or len(values) != 2 + count:
        return INVALID_RESULT
    if count > MAX_RETURNS:
        return INVALID_RESULT
    if any(abs(value) > MAX_SAMPLE for value in values[2:]):
        return INVALID_RESULT

    returns = sorted(value / SCALE for value in values[2:])
    confidence_level = confidence_micro / SCALE
    quantile = 1.0 - confidence_level
    position = (len(returns) - 1) * quantile
    lower_index = int(position)
    fraction = position - lower_index
    if lower_index == len(returns) - 1:
        threshold = returns[-1]
    else:
        threshold = returns[lower_index] * (1.0 - fraction) + returns[lower_index + 1] * fraction
    tail = [value for value in returns if value <= threshold]
    return -sum(tail) / len(tail)
