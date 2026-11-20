"""Independent reference: sieve primes and compute classes bottom-up."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_PRIME,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    _decode,
)


def _sieve(limit: int) -> bytearray:
    prime = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        prime[0] = 0
    if limit >= 1:
        prime[1] = 0
    candidate = 2
    while candidate * candidate <= limit:
        if prime[candidate]:
            multiple = candidate * candidate
            while multiple <= limit:
                prime[multiple] = 0
                multiple += candidate
        candidate += 1
    return prime


def _smallest_prime_factors(limit: int) -> list[int]:
    spf = list(range(limit + 1))
    if limit >= 0:
        spf[0] = 0
    if limit >= 1:
        spf[1] = 1
    candidate = 2
    while candidate * candidate <= limit:
        if spf[candidate] == candidate:
            multiple = candidate * candidate
            while multiple <= limit:
                if spf[multiple] == multiple:
                    spf[multiple] = candidate
                multiple += candidate
        candidate += 1
    return spf


def _bottom_up_class(limit: int, direction: int, target: int) -> int:
    prime = _sieve(limit)
    spf = _smallest_prime_factors(limit + 1)
    classes = [0] * (limit + 1)
    for value in range(2, target + 1):
        if not prime[value]:
            continue
        neighbor = value + direction
        result = 1
        while neighbor > 1:
            factor = spf[neighbor]
            if factor > 3:
                result = max(result, classes[factor] + 1)
            while neighbor % factor == 0:
                neighbor //= factor
        classes[value] = result
    return classes[target]


def expected_result(values: Sequence[int], input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    effective_length = (len(values) if input_length is None and isinstance(values, (list, tuple))
                        else input_length)
    if effective_length is None:
        return INVALID_RESULT
    decoded = _decode(values, input_is_null, effective_length)
    if decoded is None:
        return INVALID_RESULT
    prime, direction = decoded
    if not _sieve(prime)[prime]:
        return INVALID_RESULT
    return _bottom_up_class(prime, direction, prime)

