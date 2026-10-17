"""Oracle for the bounded pinned Python Sharpe-ratio calculation."""

from __future__ import annotations

MAX_SAMPLE_COUNT = 64
MAX_VALID_INPUT_LENGTH = MAX_SAMPLE_COUNT + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
SCALE = 1_000_000
MIN_RETURN_MICRO = -200_000
MAX_RETURN_MICRO = 200_000
MIN_RISK_FREE_MICRO = -100_000
MAX_RISK_FREE_MICRO = 100_000
INVALID_RESULT = -1e300
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Calculate source-order non-annualized Sharpe ratio for bounded input."""
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    count = values[0]
    if not 2 <= count <= MAX_SAMPLE_COUNT:
        return INVALID_RESULT
    if len(values) != count + 2:
        return INVALID_RESULT

    returns_micro = values[1:-1]
    risk_free_micro = values[-1]
    if (any(not MIN_RETURN_MICRO <= value <= MAX_RETURN_MICRO for value in returns_micro)
            or not MIN_RISK_FREE_MICRO <= risk_free_micro <= MAX_RISK_FREE_MICRO):
        return INVALID_RESULT
    if all(value == returns_micro[0] for value in returns_micro[1:]):
        return INVALID_RESULT

    returns = [value / SCALE for value in returns_micro]
    risk_free_rate = risk_free_micro / SCALE
    mean_return = sum(returns) / len(returns)
    excess_return = mean_return - risk_free_rate
    variance = sum((value - mean_return) ** 2 for value in returns) / (len(returns) - 1)
    standard_deviation = variance**0.5
    if standard_deviation == 0.0:
        return INVALID_RESULT
    return excess_return / standard_deviation
