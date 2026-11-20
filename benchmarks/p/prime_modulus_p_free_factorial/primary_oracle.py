"""Wilson-block reference for a factorial with all prime factors removed."""

from __future__ import annotations

I64_MAX = (1 << 63) - 1
MAX_PRIME = 1009
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
WORKSPACE_BYTES = 16384


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    n, prime = values
    if not 0 <= n <= I64_MAX or not 2 <= prime <= MAX_PRIME or not _is_prime(prime):
        return None
    return n, prime


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, prime = decoded
    factorial = [1] * prime
    for value in range(1, prime):
        factorial[value] = factorial[value - 1] * value % prime

    result = 1
    remaining = n
    while remaining > 0:
        quotient, residue = divmod(remaining, prime)
        block = factorial[residue]
        if quotient & 1:
            block = (-block) % prime
        result = result * block % prime
        remaining = quotient
    return result
