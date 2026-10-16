"""Reference the bounded speed-of-sound formula for a fluid."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 2
MIN_DENSITY = 1
MAX_DENSITY = 1_000
MIN_BULK_MODULUS = 1
MAX_BULK_MODULUS = 1_000_000_000


def expected_result(values: list[int]) -> float:
    """Decode `[density, bulk_modulus]` and preserve division-before-power order."""
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    density, bulk_modulus = values
    if (not MIN_DENSITY <= density <= MAX_DENSITY
            or not MIN_BULK_MODULUS <= bulk_modulus <= MAX_BULK_MODULUS):
        return INVALID_RESULT
    return (bulk_modulus / density) ** 0.5
