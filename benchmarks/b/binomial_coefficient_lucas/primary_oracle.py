"""Factorial-table implementation of Lucas' theorem for a small prime."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_PRIME = 2
MAX_PRIME = 1009
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
WORKSPACE_BYTES = 16_384


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    divisor = 3
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 2
    return True


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
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    n, k, prime = values
    if (n < 0 or k < 0 or k > n or not MIN_PRIME <= prime <= MAX_PRIME
            or not _is_prime(prime)):
        return None
    return n, k, prime


def _factorial_tables(prime: int) -> tuple[list[int], list[int]]:
    factorial = [1] * prime
    for value in range(1, prime):
        factorial[value] = factorial[value - 1] * value % prime

    inverse_factorial = [1] * prime
    inverse_factorial[-1] = pow(factorial[-1], prime - 2, prime)
    for value in range(prime - 1, 0, -1):
        inverse_factorial[value - 1] = inverse_factorial[value] * value % prime
    return factorial, inverse_factorial


def lucas_coefficient(n: int, k: int, prime: int) -> int:
    factorial, inverse_factorial = _factorial_tables(prime)
    result = 1
    while n or k:
        n_digit = n % prime
        k_digit = k % prime
        if k_digit > n_digit:
            return 0
        digit_result = factorial[n_digit]
        digit_result = digit_result * inverse_factorial[k_digit] % prime
        digit_result = digit_result * inverse_factorial[n_digit - k_digit] % prime
        result = result * digit_result % prime
        n //= prime
        k //= prime
    return result


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, k, prime = decoded
    return lucas_coefficient(n, k, prime)
