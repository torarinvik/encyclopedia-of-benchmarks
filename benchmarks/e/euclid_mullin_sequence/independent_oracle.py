"""Independent factor-candidate reference using a bounded prime sieve."""

from __future__ import annotations

from collections.abc import Sequence
from math import isqrt

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_CANDIDATE,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    index = values[0]
    return index if 1 <= index <= MAX_N else None


def _primes_through(limit: int) -> list[int]:
    prime_flags = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        prime_flags[0] = 0
    if limit >= 1:
        prime_flags[1] = 0
    candidate = 2
    while candidate <= limit // candidate:
        if prime_flags[candidate]:
            for multiple in range(candidate * candidate, limit + 1, candidate):
                prime_flags[multiple] = 0
        candidate += 1
    return [value for value in range(2, limit + 1) if prime_flags[value]]


def _least_prime_factor_from_sieve(value: int, primes: Sequence[int]) -> int:
    for prime in primes:
        if prime > value // prime:
            break
        if value % prime == 0:
            return prime
    return value


def _term(index: int, primes: Sequence[int]) -> int:
    product = 1
    term = 1
    for _ in range(index):
        term = _least_prime_factor_from_sieve(product + 1, primes)
        product *= term
    return term


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the term using prime-only factor candidates, or -1 if invalid."""
    index = _parse(values, input_is_null, input_length)
    if index is None:
        return -1
    primes = _primes_through(isqrt(MAX_CANDIDATE))
    return _term(index, primes)
