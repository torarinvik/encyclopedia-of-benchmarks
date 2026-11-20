"""Independent trial-division prime stream and adjacent-triple classifier."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    FIELD_BASE,
    INVALID_RESULT,
    MAX_LIMIT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MIN_LIMIT,
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
    limit = values[0]
    if not MIN_LIMIT <= limit <= MAX_LIMIT:
        return None
    return limit


def _is_prime_by_trial_division(candidate: int, earlier_primes: list[int]) -> bool:
    for divisor in earlier_primes:
        if divisor * divisor > candidate:
            break
        if candidate % divisor == 0:
            return False
    return True


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Generate primes incrementally by trial division, then inspect triples."""
    limit = _parse(values, input_is_null, input_length)
    if limit is None:
        return INVALID_RESULT

    primes: list[int] = []
    strong = weak = balanced = 0
    for candidate in range(2, 2 * limit + 1):
        if not _is_prime_by_trial_division(candidate, primes):
            continue
        primes.append(candidate)
        if len(primes) < 3:
            continue
        previous, current, following = primes[-3:]
        if current < 3 or current > limit:
            continue
        left_twice = 2 * current
        neighbor_sum = previous + following
        if left_twice > neighbor_sum:
            strong += 1
        elif left_twice < neighbor_sum:
            weak += 1
        else:
            balanced += 1
    return strong * FIELD_BASE * FIELD_BASE + weak * FIELD_BASE + balanced
