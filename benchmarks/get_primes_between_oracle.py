"""Independent bounded oracle for primes strictly between prime endpoints."""

from __future__ import annotations

from collections.abc import Sequence

MIN_ENDPOINT = 2
MAX_ENDPOINT = 997
MAX_OUTPUT_BYTES = 1024


def is_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def primes_between(values: Sequence[int]) -> tuple[int, ...] | None:
    if (
        not isinstance(values, (tuple, list))
        or len(values) != 2
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return None
    p1, p2 = values
    if not MIN_ENDPOINT <= p1 <= MAX_ENDPOINT or not MIN_ENDPOINT <= p2 <= MAX_ENDPOINT:
        return None
    if p1 >= p2 or not is_prime(p1) or not is_prime(p2):
        return None

    primes = tuple(candidate for candidate in range(p1 + 1, p2) if is_prime(candidate))
    return primes if primes else None


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    primes = primes_between(values)
    if primes is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null:
        return -2, b""

    output = ",".join(str(prime) for prime in primes).encode("ascii")
    if len(output) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_capacity < len(output):
        return -2, b""
    return len(output), output
