"""Oracle for a bounded deterministic replay of the JavaScript Shor sketch."""
from __future__ import annotations

from collections.abc import Sequence
from math import gcd

INVALID_RESULT = -1
MIN_MODULUS = 2
MAX_MODULUS = 255
MIN_ATTEMPTS = 1
MAX_ATTEMPTS = 16
MAX_VALID_INPUT_LENGTH = 18
MAX_PARSEABLE_INPUT_LENGTH = 19


def _base_result(modulus: int, base: int) -> int | None:
    """Return the source gcd result, or None when the source retries this base."""
    common = gcd(base, modulus)
    if common != 1:
        return common

    power = base % modulus
    order = 1
    while power != 1 and order < modulus - 1:
        power = (power * base) % modulus
        order += 1
    if power != 1:
        return INVALID_RESULT
    if order % 2 == 1:
        return None

    half_power = pow(base, order // 2, modulus)
    upper = half_power + 1
    lower = half_power - 1
    if upper % modulus == 0 or lower % modulus == 0:
        return None
    common = gcd(upper, modulus)
    if common != 1:
        return common
    return gcd(lower, modulus)


def expected_result(values: Sequence[int] | None) -> int:
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT

    modulus, attempts = values[:2]
    if (not MIN_MODULUS <= modulus <= MAX_MODULUS
            or not MIN_ATTEMPTS <= attempts <= MAX_ATTEMPTS
            or len(values) != 2 + attempts):
        return INVALID_RESULT
    bases = values[2:]
    if any(not 2 <= base <= modulus for base in bases):
        return INVALID_RESULT

    for base in bases:
        result = _base_result(modulus, base)
        if result == INVALID_RESULT:
            return INVALID_RESULT
        if result is not None:
            return result
    return INVALID_RESULT
