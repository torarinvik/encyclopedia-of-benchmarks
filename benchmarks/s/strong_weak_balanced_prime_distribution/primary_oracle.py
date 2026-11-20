"""Count number-theoretic strong, weak, and balanced primes in a bounded prefix."""

from __future__ import annotations

from collections.abc import Sequence
from math import isqrt

MIN_LIMIT = 3
MAX_LIMIT = 100_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1
FIELD_BASE = 100_000


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
    limit = values[0]
    if not MIN_LIMIT <= limit <= MAX_LIMIT:
        return None
    return limit


def _pack(strong: int, weak: int, balanced: int) -> int:
    """Pack three counts as fixed-width base-100000 digits."""
    return strong * FIELD_BASE * FIELD_BASE + weak * FIELD_BASE + balanced


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Sieve through twice the bound, then classify adjacent-prime triples."""
    limit = _parse(values, input_is_null, input_length)
    if limit is None:
        return INVALID_RESULT

    ceiling = 2 * limit
    prime = bytearray(b"\x01") * (ceiling + 1)
    prime[0] = 0
    prime[1] = 0
    for divisor in range(2, isqrt(ceiling) + 1):
        if prime[divisor]:
            start = divisor * divisor
            count = (ceiling - start) // divisor + 1
            prime[start:ceiling + 1:divisor] = b"\x00" * count

    strong = weak = balanced = 0
    previous = current = 0
    for candidate in range(2, ceiling + 1):
        if not prime[candidate]:
            continue
        if previous and 3 <= current <= limit:
            left_twice = 2 * current
            neighbor_sum = previous + candidate
            if left_twice > neighbor_sum:
                strong += 1
            elif left_twice < neighbor_sum:
                weak += 1
            else:
                balanced += 1
        previous, current = current, candidate
    return _pack(strong, weak, balanced)
