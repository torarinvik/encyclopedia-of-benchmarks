"""Pocklington n-1 certificate verification by modular exponentiation."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 65_535
MAX_FACTORS = 6
MAX_EXPONENT = 16
MAX_VALID_INPUT_LENGTH = 3 + 3 * MAX_FACTORS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
REJECTED_RESULT = 0
ACCEPTED_RESULT = 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[int, int, int]], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    n, count = values[0], values[1]
    if not 3 <= n <= MAX_N or not 1 <= count <= MAX_FACTORS:
        return None
    if len(values) != 3 + 3 * count:
        return None
    factors: list[tuple[int, int, int]] = []
    previous_prime = 1
    factored_part = 1
    for index in range(count):
        prime, exponent, witness = values[2 + 3 * index:5 + 3 * index]
        if (prime <= previous_prime or prime < 2
                or not 1 <= exponent <= MAX_EXPONENT
                or not 1 <= witness < n):
            return None
        previous_prime = prime
        factors.append((prime, exponent, witness))
        for _ in range(exponent):
            if factored_part > (n - 1) // prime:
                return None
            factored_part *= prime
    cofactor = values[2 + 3 * count]
    if not 1 <= cofactor <= n - 1 or factored_part * cofactor != n - 1:
        return None
    return n, factors, factored_part


def _is_prime_by_trial_division(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor = 3 if divisor == 2 else divisor + 2
    return True


def _pow_mod(base: int, exponent: int, modulus: int) -> int:
    result = 1
    factor = base % modulus
    while exponent > 0:
        if exponent & 1:
            result = (result * factor) % modulus
        factor = (factor * factor) % modulus
        exponent >>= 1
    return result


def _gcd(left: int, right: int) -> int:
    while right:
        left, right = right, left % right
    return left


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, factors, factored_part = parsed
    if any(not _is_prime_by_trial_division(prime) for prime, _, _ in factors):
        return INVALID_RESULT
    if factored_part * factored_part <= n:
        return REJECTED_RESULT
    for prime, _, witness in factors:
        if _pow_mod(witness, n - 1, n) != 1:
            return REJECTED_RESULT
        reduced_power = _pow_mod(witness, (n - 1) // prime, n)
        normalized_difference = (reduced_power + n - 1) % n
        if _gcd(normalized_difference, n) != 1:
            return REJECTED_RESULT
    return ACCEPTED_RESULT
