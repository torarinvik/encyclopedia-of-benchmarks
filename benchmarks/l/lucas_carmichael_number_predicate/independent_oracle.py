"""Sieve-and-divisor-reference for Lucas–Carmichael classification."""

from __future__ import annotations

from collections.abc import Sequence
from math import isqrt

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALUE,
    MAX_VALID_INPUT_LENGTH,
    MIN_VALUE,
)

MAX_SIEVE_BOUND = isqrt(MAX_VALUE)
WORKSPACE_BYTES = 128


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return None
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    value = values[0]
    return value if MIN_VALUE <= value <= MAX_VALUE else None


def _sieve(bound: int) -> tuple[int, ...]:
    prime = bytearray(b"\x01") * (bound + 1)
    prime[0] = 0
    if bound >= 1:
        prime[1] = 0
    for candidate in range(2, isqrt(bound) + 1):
        if prime[candidate]:
            for multiple in range(candidate * candidate, bound + 1, candidate):
                prime[multiple] = 0
    return tuple(index for index, is_prime in enumerate(prime) if is_prime)


_PRIMES = _sieve(MAX_SIEVE_BOUND)


def _classify_from_sieved_divisors(value: int) -> int:
    """Check original-n divisibility for each sieved p, then its cofactor."""
    cofactor = value
    has_small_prime_factor = False
    for prime in _PRIMES:
        if prime > value // prime:
            break
        if value % prime != 0:
            continue
        has_small_prime_factor = True
        if value % (prime * prime) == 0:
            return 0
        if (value + 1) % (prime + 1) != 0:
            return 0
        cofactor //= prime

    if not has_small_prime_factor:
        return 0
    if cofactor > 1 and (value + 1) % (cofactor + 1) != 0:
        return 0
    return 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Use a fixed sieve, checking factors against the original input."""
    value = _decode(values, input_is_null, input_length)
    return -1 if value is None else _classify_from_sieved_divisors(value)
