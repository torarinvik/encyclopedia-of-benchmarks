"""Independent segmented-sieve oracle for bounded prime-count queries."""

from __future__ import annotations

from math import isqrt

MIN_INPUT = 0
MAX_INPUT = 100_000_000
SEGMENT_SIZE = 1 << 16


def expected_output(value: int) -> int:
    """Count primes through value by segmented enumeration, not Lehmer recursion."""
    if type(value) is not int or not MIN_INPUT <= value <= MAX_INPUT:
        return -1
    if value < 2:
        return 0

    base_limit = isqrt(value)
    base_sieve = bytearray(b"\x01") * (base_limit + 1)
    base_sieve[0:2] = b"\x00\x00"
    for prime in range(2, isqrt(base_limit) + 1):
        if base_sieve[prime]:
            first = prime * prime
            base_sieve[first::prime] = b"\x00" * ((base_limit - first) // prime + 1)
    base_primes = [candidate for candidate in range(2, base_limit + 1) if base_sieve[candidate]]

    count = 0
    for low in range(2, value + 1, SEGMENT_SIZE):
        high = min(low + SEGMENT_SIZE, value + 1)
        segment = bytearray(b"\x01") * (high - low)
        for prime in base_primes:
            if prime * prime >= high:
                break
            first = max(prime * prime, ((low + prime - 1) // prime) * prime)
            if first < high:
                segment[first - low::prime] = b"\x00" * ((high - 1 - first) // prime + 1)
        count += segment.count(1)
    return count
