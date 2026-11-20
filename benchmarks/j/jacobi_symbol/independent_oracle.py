"""Prime-factor definition oracle for bounded Jacobi symbols."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_MODULUS = 1_000_000_000
MAX_PARSEABLE_INPUT_LENGTH = 3


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values) or input_length != 2:
        return None
    numerator, denominator = values
    if (not 1 <= denominator <= MAX_MODULUS or denominator % 2 == 0
            or not 0 <= numerator < denominator):
        return None
    return numerator, denominator


def _legendre_by_euler(value: int, prime: int) -> int:
    residue = value % prime
    if residue == 0:
        return 0
    power = pow(residue, (prime - 1) // 2, prime)
    return 1 if power == 1 else -1


def _jacobi_from_factorization(numerator: int, denominator: int) -> int:
    if denominator == 1:
        return 1
    if numerator == 0:
        return 0
    remaining = denominator
    symbol = 1
    divisor = 2
    while divisor <= remaining // divisor:
        if remaining % divisor == 0:
            exponent = 0
            while remaining % divisor == 0:
                remaining //= divisor
                exponent += 1
            legendre = _legendre_by_euler(numerator, divisor)
            if legendre == 0:
                return 0
            if exponent % 2 == 1:
                symbol *= legendre
        divisor = 3 if divisor == 2 else divisor + 2
    if remaining > 1:
        symbol *= _legendre_by_euler(numerator, remaining)
    return symbol


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    numerator, denominator = parsed
    return _jacobi_from_factorization(numerator, denominator) + 1


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
