"""Oracle for TheAlgorithms/Python price_plus_tax."""

from __future__ import annotations

SCALE = 1_000_000
MAX_PRICE_MICRO = 1_000_000_000_000
MAX_TAX_RATE_MICRO = 1_000_000
MAX_INPUT_LENGTH = 3  # admit one extra packed value for malformed-input coverage
INVALID_RESULT = -1e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    price_micro, tax_rate_micro = values
    if (not 0 <= price_micro <= MAX_PRICE_MICRO
            or not 0 <= tax_rate_micro <= MAX_TAX_RATE_MICRO):
        return INVALID_RESULT

    price = price_micro / SCALE
    tax_rate = tax_rate_micro / SCALE
    return price * (1.0 + tax_rate)
