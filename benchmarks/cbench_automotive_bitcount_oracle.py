"""Independent oracle for the bounded cBench automotive bitcount profile."""

from __future__ import annotations

from functools import lru_cache

MAX_ITERATIONS = 1_125_000
ALGORITHM_NAMES = (
    "Optimized 1 bit/loop counter",
    "Ratko's mystery algorithm",
    "Recursive bit count by nybbles",
    "Non-recursive bit count by nybbles",
    "Non-recursive bit count by bytes (BW)",
    "Non-recursive bit count by bytes (AR)",
    "Shift and count bits",
)
REFERENCE_CHECKSUMS = (13244094,) * 7
REFERENCE_RESULT = 370834632


def _floor_sum(n: int, modulus: int, multiplier: int, offset: int) -> int:
    """Sum floor((multiplier*i + offset) / modulus) for 0 <= i < n."""
    total = 0
    while True:
        if multiplier >= modulus:
            total += (n - 1) * n * (multiplier // modulus) // 2
            multiplier %= modulus
        if offset >= modulus:
            total += n * (offset // modulus)
            offset %= modulus
        top = multiplier * n + offset
        if top < modulus:
            return total
        n, offset = top // modulus, top % modulus
        modulus, multiplier = multiplier, modulus


@lru_cache(maxsize=128)
def algorithm_checksums(iterations: int) -> tuple[int, ...] | None:
    """Return the seven identical bit totals, or None outside the profile.

    Dataset 1 produces the positive stream 1, 14, 27, ... below 2**24.
    Every selected kernel counts the same set bits on that stream. The floor
    sum counts each bit position across the arithmetic progression without
    copying any of the seven source counting implementations.
    """
    if type(iterations) is not int or not 0 <= iterations <= MAX_ITERATIONS:
        return None
    total = 0
    for bit in range(24):
        period = 1 << (bit + 1)
        half = period >> 1
        total += (_floor_sum(iterations, period, 13, 1 + half)
                  - _floor_sum(iterations, period, 13, 1))
    return (total,) * 7


def expected_result(iterations: int) -> int:
    """Return the suite's one-based weighted checksum of the seven totals."""
    checksums = algorithm_checksums(iterations)
    if checksums is None:
        return -1
    return sum((index + 1) * total for index, total in enumerate(checksums))
