"""Sieve-based independent primality reference for Chernick multipliers."""

from __future__ import annotations

from math import isqrt

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_FACTOR,
    MAX_MULTIPLIER,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MIN_N,
)


def _primes_through(bound: int) -> tuple[int, ...]:
    sieve = bytearray(b"\x01") * (bound + 1)
    if bound >= 0:
        sieve[0] = 0
    if bound >= 1:
        sieve[1] = 0
    for candidate in range(2, isqrt(bound) + 1):
        if sieve[candidate]:
            start = candidate * candidate
            sieve[start:bound + 1:candidate] = b"\x00" * (((bound - start) // candidate) + 1)
    return tuple(index for index, prime in enumerate(sieve) if prime)


_SMALL_PRIMES = _primes_through(isqrt(MAX_FACTOR))


def _is_prime_by_sieve(value: int) -> bool:
    if value < 2:
        return False
    for prime in _SMALL_PRIMES:
        if prime > value // prime:
            return True
        if value % prime == 0:
            return value == prime
    return True


def _is_admissible_multiplier(n: int, multiplier: int) -> bool:
    if n > 4 and multiplier % (1 << (n - 4)) != 0:
        return False
    if n > 5 and multiplier % 5 != 0:
        return False
    return True


def _all_factors_prime(n: int, multiplier: int) -> bool:
    if not _is_prime_by_sieve(6 * multiplier + 1):
        return False
    if not _is_prime_by_sieve(12 * multiplier + 1):
        return False
    for exponent in range(1, n - 1):
        if not _is_prime_by_sieve((9 * multiplier << exponent) + 1):
            return False
    return True


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) != 1 or not MIN_N <= values[0] <= MAX_N:
        return -1

    n = values[0]
    for multiplier in range(1, MAX_MULTIPLIER + 1):
        if (_is_admissible_multiplier(n, multiplier)
                and _all_factors_prime(n, multiplier)):
            return multiplier
    return -1
