"""Exhaustive bounded root search used as an independent Hensel verifier."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_PARSEABLE_INPUT_LENGTH = 10


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[int, int, int, int, tuple[int, ...], int] | None:
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
    degree, prime, exponent, seed = values[:4]
    if not 1 <= degree <= 4 or not 2 <= prime <= 43 or not 1 <= exponent <= 6:
        return None
    if not 0 <= seed < prime or input_length != degree + 5:
        return None
    for divisor in range(2, prime):
        if divisor * divisor > prime:
            break
        if prime % divisor == 0:
            return None
    modulus = prime ** exponent
    if modulus > 100_000:
        return None
    coefficients = tuple(values[4:])
    if len(coefficients) != degree + 1 or any(not -1000 <= c <= 1000 for c in coefficients):
        return None
    return degree, prime, exponent, seed, coefficients, modulus


def _evaluate(coefficients: tuple[int, ...], x: int, modulus: int) -> int:
    result = 0
    for coefficient in reversed(coefficients):
        result = (result * x + coefficient) % modulus
    return result


def _derivative(coefficients: tuple[int, ...], x: int, prime: int) -> int:
    result = 0
    for power in range(len(coefficients) - 1, 0, -1):
        result = (result * x + power * coefficients[power]) % prime
    return result


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    degree, prime, _exponent, seed, coefficients, modulus = parsed
    if _evaluate(coefficients, seed, prime) != 0 or _derivative(coefficients, seed, prime) == 0:
        return INVALID_RESULT
    # Search the entire residue class seeded modulo p; simple-root Hensel
    # uniqueness guarantees exactly one match when a lift exists.
    for candidate in range(seed, modulus, prime):
        if _evaluate(coefficients, candidate, modulus) == 0:
            return candidate
    return INVALID_RESULT


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
