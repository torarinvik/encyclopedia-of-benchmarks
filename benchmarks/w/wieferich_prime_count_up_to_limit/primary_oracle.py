"""Sieve primes, then use binary modular exponentiation for the Wieferich test."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LIMIT = 5_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 8_192
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    actual_length = len(values) if input_length is None else input_length
    if actual_length != len(values) or len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    limit = values[0]
    return limit if 2 <= limit <= MAX_LIMIT else None


def _binary_mod_pow(base: int, exponent: int, modulus: int) -> int:
    result = 1
    while exponent > 0:
        if exponent & 1:
            result = (result * base) % modulus
        base = (base * base) % modulus
        exponent >>= 1
    return result


def wieferich_prime_count_up_to_limit(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Count odd primes p<=N satisfying 2^(p-1) == 1 modulo p^2."""
    limit = _parse(values, input_is_null, input_length)
    if limit is None:
        return INVALID_RESULT

    prime = bytearray(b"\x01") * (limit + 1)
    prime[0] = 0
    prime[1] = 0
    divisor = 2
    while divisor * divisor <= limit:
        if prime[divisor]:
            multiple = divisor * divisor
            while multiple <= limit:
                prime[multiple] = 0
                multiple += divisor
        divisor += 1

    count = 0
    for candidate in range(3, limit + 1, 2):
        if prime[candidate]:
            modulus = candidate * candidate
            if _binary_mod_pow(2, candidate - 1, modulus) == 1:
                count += 1
    return count
