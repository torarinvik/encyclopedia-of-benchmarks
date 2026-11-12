"""Primary Legendre-formula oracle for bounded prime counting."""
from __future__ import annotations

from math import isqrt

MIN_INPUT = 0
MAX_INPUT = 10_000


def expected_output(value: int) -> int:
    """Evaluate Legendre's partial-sieve formula using recursive inclusion-exclusion."""
    if type(value) is not int or not MIN_INPUT <= value <= MAX_INPUT:
        return -1
    if value < 2:
        return 0

    root = isqrt(value)
    sieve = bytearray(b"\x01") * (root + 1)
    sieve[0] = 0
    if root >= 1:
        sieve[1] = 0
    for candidate in range(2, isqrt(root) + 1):
        if sieve[candidate]:
            first = candidate * candidate
            sieve[first::candidate] = b"\x00" * ((root - first) // candidate + 1)
    primes = [candidate for candidate in range(2, root + 1) if sieve[candidate]]

    def phi(bound: int, used: int) -> int:
        if bound == 0:
            return 0
        if used == 0:
            return bound
        if used == 1:
            return bound - bound // 2
        prime = primes[used - 1]
        if bound < prime:
            return 1
        return phi(bound, used - 1) - phi(bound // prime, used - 1)

    prime_count = len(primes)
    return phi(value, prime_count) + prime_count - 1
