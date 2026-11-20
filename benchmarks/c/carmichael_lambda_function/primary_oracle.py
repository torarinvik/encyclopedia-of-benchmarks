"""Prime-power decomposition for Carmichael's universal exponent."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd

MAX_N = 1_024
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MIN_RESULT = 1
MAX_RESULT = MAX_N - 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values) or len(values) != 1:
        return None
    n = values[0]
    if not 1 <= n <= MAX_N:
        return None
    return n


def _lcm(left: int, right: int) -> int:
    return left // gcd(left, right) * right


def _prime_power_lambda(prime: int, exponent: int, prime_power: int) -> int:
    if prime == 2:
        if exponent == 1:
            return 1
        if exponent == 2:
            return 2
        return prime_power // 4
    return (prime_power // prime) * (prime - 1)


def _factorization_lambda(n: int) -> int:
    if n == 1:
        return 1
    remaining = n
    result = 1
    prime = 2
    while prime * prime <= remaining:
        if remaining % prime != 0:
            prime = 3 if prime == 2 else prime + 2
            continue
        prime_power = 1
        exponent = 0
        while remaining % prime == 0:
            remaining //= prime
            prime_power *= prime
            exponent += 1
        result = _lcm(result, _prime_power_lambda(prime, exponent, prime_power))
        prime = 3 if prime == 2 else prime + 2
    if remaining > 1:
        result = _lcm(result, remaining - 1)
    return result


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    n = _parse(values, input_is_null, input_length)
    if n is None:
        return INVALID_RESULT
    return _factorization_lambda(n)
