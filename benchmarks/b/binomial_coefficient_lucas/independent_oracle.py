"""Independent exact-small-digit reference for Lucas' theorem."""

from __future__ import annotations

from math import comb, isqrt

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PRIME,
    MIN_PRIME,
)


def _prime(value: int) -> bool:
    return value >= 2 and all(value % divisor for divisor in range(2, isqrt(value) + 1))


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 3:
        return None
    n, k, prime = values
    if (n < 0 or k < 0 or k > n or not MIN_PRIME <= prime <= MAX_PRIME
            or not _prime(prime)):
        return None
    return n, k, prime


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, k, prime = decoded
    result = 1
    while n or k:
        n_digit = n % prime
        k_digit = k % prime
        if k_digit > n_digit:
            return 0
        result = result * (comb(n_digit, k_digit) % prime) % prime
        n //= prime
        k //= prime
    return result
