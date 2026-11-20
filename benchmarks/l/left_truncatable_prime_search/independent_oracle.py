"""Exhaustive bounded verifier using a prime sieve and suffix scan."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_BASE,
    MAX_DIGITS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_SEARCH_LIMIT,
    MIN_BASE,
)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values) or len(values) != 2:
        return None
    base, max_digits = values
    if not MIN_BASE <= base <= MAX_BASE or not 1 <= max_digits <= MAX_DIGITS:
        return None
    limit = 1
    for _ in range(max_digits):
        limit *= base
    if limit > MAX_SEARCH_LIMIT:
        return None
    return base, limit


def _prime_table(limit: int) -> bytearray:
    prime = bytearray(b"\x01") * limit
    if limit > 0:
        prime[0] = 0
    if limit > 1:
        prime[1] = 0
    divisor = 2
    while divisor * divisor < limit:
        if prime[divisor]:
            start = divisor * divisor
            count = (limit - 1 - start) // divisor + 1
            prime[start:limit:divisor] = b"\x00" * count
        divisor += 1
    return prime


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Scan every bounded integer and test its complete base-b suffix chain."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    base, limit = parsed
    prime = _prime_table(limit)
    best = 0
    for candidate in range(2, limit):
        leading_place = 1
        while leading_place * base <= candidate:
            leading_place *= base
        suffix = candidate
        place = leading_place
        valid = True
        while place:
            leading_digit = suffix // place
            if leading_digit == 0 or not prime[suffix]:
                valid = False
                break
            suffix %= place
            place //= base
        if valid:
            best = candidate
    return best
