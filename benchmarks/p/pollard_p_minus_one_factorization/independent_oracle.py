"""Big-exponent oracle for the bounded Pollard p−1 stage-1 profile."""

from __future__ import annotations

from math import gcd, isqrt
from typing import Sequence

ALGORITHM = "pollard_p_minus_one_factorization"
MAX_NUMBER = 1_000_000_000
MAX_BOUND = 64
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1
WORKSPACE_BYTES = 1024


def _primes_through(bound: int) -> list[int]:
    result: list[int] = []
    for candidate in range(2, bound + 1):
        if all(candidate % divisor for divisor in range(2, isqrt(candidate) + 1)):
            result.append(candidate)
    return result


def expected_result(values: Sequence[int] | None,
                    algorithm: str = ALGORITHM,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (algorithm != ALGORITHM or not isinstance(values, (list, tuple))
            or type(input_is_null) is not bool or input_is_null
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) != MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    number, bound, initial = values
    if (not 2 <= number <= MAX_NUMBER or not 2 <= bound <= MAX_BOUND
            or not 1 <= initial < number):
        return INVALID_RESULT
    divisor = gcd(initial, number)
    if divisor > 1:
        return divisor

    cumulative_exponent = 1
    for prime in _primes_through(bound):
        prime_power = prime
        while prime_power <= bound // prime:
            prime_power *= prime
        cumulative_exponent *= prime_power
        residue = pow(initial, cumulative_exponent, number)
        divisor = gcd(abs(residue - 1), number)
        if divisor > 1:
            return divisor if divisor < number else 0
    return 0
