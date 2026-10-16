"""Reference the pinned Rust present-value formula and rounding behavior."""

from __future__ import annotations

import math

MAX_FLOW_COUNT = 8
MAX_CASH_FLOWS = MAX_FLOW_COUNT
MAX_INPUT_LENGTH = 11  # one extra packed value is admitted for malformed-shape coverage
MAX_RATE_PPM = 1_000_000
MAX_CASH_FLOW_MILLI = 1_000_000
INVALID_RESULT = -1e300


def round_half_away_from_zero(value: float) -> float:
    """Match Rust f64::round(), including ties and signed zero."""
    if value == 0.0:
        return value
    return math.copysign(math.floor(abs(value) + 0.5), value)


def expected_result(values: list[int]) -> float:
    """Decode `[count, rate_ppm, cash_flow_milli...]` and return rounded PV."""
    if (not isinstance(values, list) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    count, rate_ppm = values[0], values[1]
    if (not 1 <= count <= MAX_CASH_FLOWS or len(values) != count + 2
            or rate_ppm not in (0, MAX_RATE_PPM)
            or any(abs(value) > MAX_CASH_FLOW_MILLI or value % 125 != 0
                   for value in values[2:])):
        return INVALID_RESULT

    discount_rate = rate_ppm / 1_000_000.0
    present_value = 0.0
    for index, cash_flow_milli in enumerate(values[2:]):
        cash_flow = cash_flow_milli / 1_000.0
        present_value += cash_flow / math.pow(1.0 + discount_rate, index)
    return round_half_away_from_zero(present_value * 100.0) / 100.0
