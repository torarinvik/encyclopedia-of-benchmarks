"""Exponent-profile search for the least integer with a target divisor count."""

from __future__ import annotations

from functools import lru_cache

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_DIVISOR_COUNT = 63
MAX_LIMIT = 1_000_000
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_RESULT = MAX_LIMIT
WORKSPACE_BYTES = 65536
PRIMES = (2, 3, 5, 7, 11)


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
    divisor_count, limit = values
    if not 1 <= divisor_count <= MAX_DIVISOR_COUNT or not 1 <= limit <= MAX_LIMIT:
        return None
    return divisor_count, limit


def _least_under_limit(divisor_count: int, limit: int) -> int:
    best = limit + 1

    def visit(remaining: int, max_factor: int, prime_index: int, product: int) -> None:
        nonlocal best
        if remaining == 1:
            if product < best:
                best = product
            return
        if prime_index >= len(PRIMES):
            return
        prime = PRIMES[prime_index]
        for factor in range(2, min(max_factor, remaining) + 1):
            if remaining % factor:
                continue
            candidate = product
            for _ in range(factor - 1):
                if candidate > limit // prime:
                    candidate = limit + 1
                    break
                candidate *= prime
            if candidate < best:
                visit(remaining // factor, factor, prime_index + 1, candidate)

    visit(divisor_count, divisor_count, 0, 1)
    return 0 if best > limit else best


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    return _least_under_limit(*decoded)
