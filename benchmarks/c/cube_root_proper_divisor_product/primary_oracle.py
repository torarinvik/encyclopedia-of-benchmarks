"""Prime-signature enumeration and binary-search reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_K = 50_000
MAX_RESULT = 600_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 2_400_128
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _prime_prefix(limit: int) -> list[int]:
    prefix = [0] * (limit + 1)
    for value in range(2, limit + 1):
        prefix[value] = 1
    prime = 2
    while prime <= limit // prime:
        if prefix[prime]:
            for multiple in range(prime * prime, limit + 1, prime):
                prefix[multiple] = 0
        prime += 1
    for value in range(1, limit + 1):
        prefix[value] += prefix[value - 1]
    return prefix


def _is_prime(value: int, prefix: Sequence[int]) -> bool:
    return value >= 2 and prefix[value] - prefix[value - 1] == 1


def count_tau_eight_at_most(limit: int, prime_prefix: Sequence[int]) -> int:
    """Count p^7, p^3*q, and p*q*r with distinct primes and value <= limit."""
    total = 0

    prime = 2
    while prime ** 7 <= limit:
        if _is_prime(prime, prime_prefix):
            total += 1
        prime += 1

    prime = 2
    while prime ** 3 <= limit:
        if _is_prime(prime, prime_prefix):
            q_max = limit // (prime ** 3)
            total += prime_prefix[q_max]
            if prime <= q_max:
                total -= 1
        prime += 1

    prime = 2
    while prime ** 3 < limit:
        if _is_prime(prime, prime_prefix):
            other = prime + 1
            while other <= limit:
                product = prime * other
                if product > limit:
                    break
                last_prime = limit // product
                if last_prime <= other:
                    break
                if _is_prime(other, prime_prefix):
                    total += prime_prefix[last_prime] - prime_prefix[other]
                other += 1
        prime += 1
    return total


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> int | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX
           for value in values):
        return None
    k = values[0]
    return k if 1 <= k <= MAX_K else None


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    k = _parse(values, input_length, input_is_null)
    if k is None:
        return -1
    if k == 1:
        return 1

    prime_prefix = _prime_prefix(MAX_RESULT)
    target = k - 1
    if count_tau_eight_at_most(MAX_RESULT, prime_prefix) < target:
        return -1
    low = 1
    high = MAX_RESULT
    while low < high:
        middle = low + (high - low) // 2
        if count_tau_eight_at_most(middle, prime_prefix) >= target:
            high = middle
        else:
            low = middle + 1
    return low
