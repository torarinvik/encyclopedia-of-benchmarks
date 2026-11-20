"""Small-domain segmented-sieve oracle plus pinned large published fixtures."""

from __future__ import annotations

from math import isqrt

MAX_INPUT = 1_000_000_000
DIRECT_LIMIT = 1_000_000
PUBLISHED_FIXTURES = {
    100_000_000: 279_209_790_387_276,
    1_000_000_000: 24_739_512_092_254_535,
}


def expected_result(value: int) -> int:
    """Directly sum a bounded segment sieve, or return a cited fixture.

    Values above DIRECT_LIMIT other than the two published powers of ten are
    deliberately outside this independent reference's calculation domain.
    """
    if type(value) is not int or not 0 <= value <= MAX_INPUT:
        return -1
    if value in PUBLISHED_FIXTURES:
        return PUBLISHED_FIXTURES[value]
    if value > DIRECT_LIMIT:
        raise ValueError("independent prime-sum oracle is limited to 1e6 and cited fixtures")
    if value < 2:
        return 0

    root = isqrt(value)
    base = bytearray(b"\x01") * (root + 1)
    base[0:2] = b"\x00\x00"
    for prime in range(2, isqrt(root) + 1):
        if base[prime]:
            base[prime * prime:root + 1:prime] = b"\x00" * (
                (root - prime * prime) // prime + 1)
    base_primes = [candidate for candidate in range(2, root + 1) if base[candidate]]

    total = 0
    segment_size = 1 << 15
    for low in range(2, value + 1, segment_size):
        high = min(low + segment_size, value + 1)
        segment = bytearray(b"\x01") * (high - low)
        for prime in base_primes:
            first = max(prime * prime, ((low + prime - 1) // prime) * prime)
            if first >= high:
                continue
            for composite in range(first, high, prime):
                segment[composite - low] = 0
        total += sum(low + offset for offset, is_prime in enumerate(segment) if is_prime)
    return total
