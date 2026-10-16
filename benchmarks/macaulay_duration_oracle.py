"""Oracle for TheAlgorithms/Python macaulay_duration."""

from __future__ import annotations

SCALE = 1_000_000
MAX_FACE_VALUE_MICRO = 1_000_000_000_000
MAX_RATE_MICRO = 1_000_000
MAX_PERIODS = 64
MAX_INPUT_LENGTH = 5  # admit one extra packed value for malformed-input coverage
INVALID_RESULT = -1e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 4
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    face_micro, coupon_micro, periods, yield_micro = values
    if (not 1 <= face_micro <= MAX_FACE_VALUE_MICRO
            or not 0 <= coupon_micro <= MAX_RATE_MICRO
            or not 1 <= periods <= MAX_PERIODS
            or not 1 <= yield_micro <= MAX_RATE_MICRO):
        return INVALID_RESULT

    face_value = face_micro / SCALE
    coupon_rate = coupon_micro / SCALE
    yield_rate = yield_micro / SCALE
    total_present_value = 0.0
    total_time_weighted_value = 0.0
    for period in range(1, periods + 1):
        cash_flow = face_value * coupon_rate + (face_value if period == periods else 0.0)
        time_weighted_value = (period * cash_flow) / pow(1.0 + yield_rate, period)
        total_time_weighted_value += time_weighted_value
        present_value = cash_flow / pow(1.0 + yield_rate, period)
        total_present_value += present_value
    return total_time_weighted_value / total_present_value
