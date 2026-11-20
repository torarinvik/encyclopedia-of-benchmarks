"""Digit-by-digit Hensel lifting for a bounded simple polynomial root."""

from __future__ import annotations

from collections.abc import Sequence

MAX_DEGREE = 4
MIN_PRIME = 2
MAX_PRIME = 43
MAX_EXPONENT = 6
MAX_MODULUS = 100_000
MAX_VALID_INPUT_LENGTH = 9
MAX_PARSEABLE_INPUT_LENGTH = 10
MAX_RESULT = 83_520
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int, int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 6 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    degree, prime, exponent, root = values[:4]
    if not 1 <= degree <= MAX_DEGREE or not MIN_PRIME <= prime <= MAX_PRIME:
        return None
    if not 1 <= exponent <= MAX_EXPONENT or not 0 <= root < prime:
        return None
    if input_length != degree + 5:
        return None
    for divisor in range(2, prime):
        if divisor * divisor > prime:
            break
        if prime % divisor == 0:
            return None
    modulus = 1
    for _ in range(exponent):
        if modulus > MAX_MODULUS // prime:
            return None
        modulus *= prime
    coefficients = tuple(values[4:])
    if len(coefficients) != degree + 1 or any(not -1000 <= c <= 1000 for c in coefficients):
        return None
    return degree, prime, exponent, root, coefficients


def _polynomial_mod(coefficients: tuple[int, ...], degree: int,
                    x: int, modulus: int) -> int:
    value = 0
    for index in range(degree, -1, -1):
        value = (value * x + coefficients[index]) % modulus
    return value


def _derivative_mod(coefficients: tuple[int, ...], degree: int,
                    x: int, prime: int) -> int:
    value = 0
    for index in range(degree, 0, -1):
        value = (value * x + index * coefficients[index]) % prime
    return value


def _inverse_mod_prime(value: int, prime: int) -> int | None:
    for candidate in range(1, prime):
        if value * candidate % prime == 1:
            return candidate
    return None


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    degree, prime, exponent, root, coefficients = parsed
    if _polynomial_mod(coefficients, degree, root, prime) != 0:
        return INVALID_RESULT
    derivative = _derivative_mod(coefficients, degree, root, prime)
    if derivative == 0:
        return INVALID_RESULT
    inverse = _inverse_mod_prime(derivative, prime)
    if inverse is None:
        return INVALID_RESULT

    power = prime
    for _ in range(1, exponent):
        next_power = power * prime
        residue = _polynomial_mod(coefficients, degree, root, next_power)
        quotient_digit = residue // power
        correction = (-quotient_digit * inverse) % prime
        root += correction * power
        power = next_power
    return root
