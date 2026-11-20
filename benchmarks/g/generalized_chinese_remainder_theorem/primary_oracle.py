"""Prime-power consolidation followed by coprime CRT combination."""

from __future__ import annotations

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


def _mod_inverse(value: int, modulus: int) -> int:
    old_r, r = value, modulus
    old_s, s = 1, 0
    while r:
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_s, s = s, old_s - quotient * s
    return old_s % modulus


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

    powers = [0] * (MAX_MODULUS + 1)
    residues = [0] * (MAX_MODULUS + 1)
    for residue, modulus in equations:
        remainder = modulus
        prime = 2
        while prime <= remainder:
            if remainder % prime == 0:
                prime_power = 1
                while remainder % prime == 0:
                    remainder //= prime
                    prime_power *= prime
                if prime_power > powers[prime]:
                    powers[prime] = prime_power
                    residues[prime] = residue % prime_power
            prime += 1

    for residue, modulus in equations:
        remainder = modulus
        prime = 2
        while prime <= remainder:
            if remainder % prime == 0:
                prime_power = 1
                while remainder % prime == 0:
                    remainder //= prime
                    prime_power *= prime
                if residues[prime] % prime_power != residue % prime_power:
                    return INCONSISTENT_RESULT
            prime += 1

    solution = 0
    combined_modulus = 1
    for prime in range(2, MAX_MODULUS + 1):
        modulus = powers[prime]
        if modulus == 0:
            continue
        inverse = _mod_inverse(combined_modulus % modulus, modulus)
        multiplier = ((residues[prime] - solution) * inverse) % modulus
        solution += combined_modulus * multiplier
        combined_modulus *= modulus
        solution %= combined_modulus
    return solution
