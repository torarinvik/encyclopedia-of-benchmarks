"""Oracle for bounded RSA factor recovery with explicit random bases."""
from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
MAX_PARSEABLE_LENGTH = 21
FACTOR_BASE = 65_536
MAX_RESULT = (1 << 32) - 1


def _mod_pow(base: int, exponent: int, modulus: int) -> int:
    result = 1
    power = base % modulus
    while exponent > 0:
        if exponent & 1:
            result = (result * power) % modulus
        power = (power * power) % modulus
        exponent >>= 1
    return result


def expected_result(values: Sequence[int] | None) -> int:
    if (not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT

    d, e, modulus, attempt_count = values[:4]
    if (not 1 <= d <= 1_000_000
            or not 1 <= e <= 1_000_000
            or not 3 <= modulus <= 65_535
            or modulus % 2 == 0
            or not 1 <= attempt_count <= 16
            or len(values) != 4 + attempt_count):
        return INVALID_RESULT
    k = d * e - 1
    if k <= 0 or k % 2 != 0:
        return INVALID_RESULT
    bases = values[4:]
    if any(base < 2 or base > modulus - 1 for base in bases):
        return INVALID_RESULT

    for base in bases:
        t = k
        while t % 2 == 0:
            t //= 2
            x = _mod_pow(base, t, modulus)
            factor = math.gcd(x - 1, modulus)
            if x > 1 and factor > 1:
                other = modulus // factor
                p, q = sorted((factor, other))
                result = p * FACTOR_BASE + q
                return result if 0 <= result <= MAX_RESULT else INVALID_RESULT
    return INVALID_RESULT
