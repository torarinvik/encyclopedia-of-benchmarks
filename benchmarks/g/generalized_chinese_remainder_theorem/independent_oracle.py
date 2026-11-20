"""Sequential generalized-CRT merge oracle using extended Euclid."""

from __future__ import annotations

from math import gcd
from typing import Sequence

ALGORITHM = "generalized_chinese_remainder_theorem"
MAX_EQUATIONS = 4
MAX_MODULUS = 64
MAX_PRODUCT = 16_777_216
MAX_VALID_INPUT_LENGTH = 9
MAX_PARSEABLE_INPUT_LENGTH = 10
INVALID_RESULT = -1
INCONSISTENT_RESULT = -2
WORKSPACE_BYTES = 2048


def _extended_gcd(left: int, right: int) -> tuple[int, int, int]:
    old_r, r = left, right
    old_s, s = 1, 0
    old_t, t = 0, 1
    while r:
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_s, s = s, old_s - quotient * s
        old_t, t = t, old_t - quotient * t
    return old_r, old_s, old_t


def expected_result(values: Sequence[int] | None,
                    algorithm: str = ALGORITHM,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (algorithm != ALGORITHM or not isinstance(values, (list, tuple))
            or type(input_is_null) is not bool or input_is_null
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    count = values[0]
    if not 1 <= count <= MAX_EQUATIONS or len(values) != 1 + 2 * count:
        return INVALID_RESULT

    equations: list[tuple[int, int]] = []
    product = 1
    for index in range(count):
        residue = values[1 + 2 * index]
        modulus = values[2 + 2 * index]
        if not 2 <= modulus <= MAX_MODULUS or not 0 <= residue < modulus:
            return INVALID_RESULT
        if product > MAX_PRODUCT // modulus:
            return INVALID_RESULT
        product *= modulus
        equations.append((residue, modulus))

    solution = 0
    period = 1
    for residue, modulus in equations:
        common = gcd(period, modulus)
        difference = residue - solution
        if difference % common != 0:
            return INCONSISTENT_RESULT
        reduced_modulus = modulus // common
        if reduced_modulus == 1:
            multiplier = 0
        else:
            reduced_period = period // common
            _, inverse, _ = _extended_gcd(reduced_period, reduced_modulus)
            multiplier = ((difference // common) * inverse) % reduced_modulus
        solution += period * multiplier
        period *= reduced_modulus
        solution %= period
    return solution
