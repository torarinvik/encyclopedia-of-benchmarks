"""Independent direct Eratosthenes oracle for prime-count fixtures."""
from __future__ import annotations

from math import isqrt

MIN_INPUT = 0
MAX_INPUT = 10_000


def expected_output(value: int) -> int:
    if type(value) is not int or not MIN_INPUT <= value <= MAX_INPUT:
        return -1
    if value < 2:
        return 0
    is_prime = bytearray(b"\x01") * (value + 1)
    is_prime[0:2] = b"\x00\x00"
    for candidate in range(2, isqrt(value) + 1):
        if is_prime[candidate]:
            first = candidate * candidate
            is_prime[first::candidate] = b"\x00" * ((value - first) // candidate + 1)
    return is_prime.count(1)
