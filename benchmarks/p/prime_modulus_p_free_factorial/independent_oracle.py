"""Explicit residue-block reference for the p-free factorial."""

from __future__ import annotations

from .primary_oracle import (
    I64_MAX,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PRIME,
    _is_prime,
)


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) != 2:
        return -1
    n, prime = values
    if not 0 <= n <= I64_MAX or not 2 <= prime <= MAX_PRIME or not _is_prime(prime):
        return -1

    answer = 1
    remaining = n
    while remaining > 0:
        quotient, tail = divmod(remaining, prime)
        full_block = 1
        for residue in range(1, prime):
            full_block = full_block * residue % prime
        tail_block = 1
        for residue in range(1, tail + 1):
            tail_block = tail_block * residue % prime
        level_product = pow(full_block, quotient, prime) * tail_block % prime
        answer = answer * level_product % prime
        remaining = quotient
    return answer
