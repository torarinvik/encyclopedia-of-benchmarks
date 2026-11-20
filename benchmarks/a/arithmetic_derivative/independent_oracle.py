"""Recursive Leibniz-rule reference for the arithmetic derivative."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n = values[0]
    return n if 0 <= n <= MAX_N else None


def _smallest_prime_factor(n: int) -> int:
    if n % 2 == 0:
        return 2
    divisor = 3
    while divisor <= n // divisor:
        if n % divisor == 0:
            return divisor
        divisor += 2
    return n


def _by_product_rule(n: int) -> int:
    if n < 2:
        return 0
    prime = _smallest_prime_factor(n)
    cofactor = n // prime
    return prime * _by_product_rule(cofactor) + cofactor


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    n = _parse(values, input_is_null, input_length)
    return INVALID_RESULT if n is None else _by_product_rule(n)
