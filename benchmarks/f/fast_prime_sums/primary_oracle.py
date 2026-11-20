"""Meissel–Lehmer-style weighted prime-sum reference for a bounded domain."""

from __future__ import annotations

from math import isqrt

MAX_INPUT = 1_000_000_000
SIEVE_LIMIT = 32_000
PHI_ROWS = 12
PHI_COLUMNS = 30_000


def _integer_cuberoot(value: int) -> int:
    low, high = 0, 1
    while high * high * high <= value:
        high *= 2
    while low + 1 < high:
        middle = (low + high) // 2
        if middle * middle * middle <= value:
            low = middle
        else:
            high = middle
    return low


def expected_result(value: int) -> int:
    """Return the sum of primes <= value, or -1 outside the profile."""
    if type(value) is not int or not 0 <= value <= MAX_INPUT:
        return -1

    composite = bytearray(SIEVE_LIMIT + 1)
    for prime in range(2, isqrt(SIEVE_LIMIT) + 1):
        if not composite[prime]:
            composite[prime * prime:SIEVE_LIMIT + 1:prime] = bytes(
                [1]) * ((SIEVE_LIMIT - prime * prime) // prime + 1)

    primes: list[int] = []
    prime_count = [0] * (SIEVE_LIMIT + 1)
    prime_sum = [0] * (SIEVE_LIMIT + 1)
    for candidate in range(2, SIEVE_LIMIT + 1):
        if not composite[candidate]:
            primes.append(candidate)
        prime_count[candidate] = prime_count[candidate - 1] + int(not composite[candidate])
        prime_sum[candidate] = prime_sum[candidate - 1] + (
            candidate if not composite[candidate] else 0)

    phi = [[0] * PHI_COLUMNS for _ in range(PHI_ROWS)]
    for n in range(PHI_COLUMNS):
        phi[0][n] = n * (n + 1) // 2
    for row in range(1, PHI_ROWS):
        prime = primes[row - 1]
        previous = phi[row - 1]
        current = phi[row]
        for n in range(PHI_COLUMNS):
            current[n] = previous[n] - prime * previous[n // prime]

    def weighted_phi(n: int, count: int) -> int:
        if n <= 0:
            return 0
        if count == 0:
            return n * (n + 1) // 2
        prime = primes[count - 1]
        if n <= prime:
            return 1
        if count < PHI_ROWS and n < PHI_COLUMNS:
            return phi[count][n]
        if n < SIEVE_LIMIT and prime * prime >= n:
            return prime_sum[n] - prime_sum[prime] + 1
        if n < SIEVE_LIMIT and prime * prime * prime >= n:
            result = prime_sum[n] - prime_sum[prime] + 1
            limit = prime_count[isqrt(n)]
            for index in range(count, limit):
                other = primes[index]
                result += other * (prime_sum[n // other] - prime_sum[other - 1])
            return result
        return weighted_phi(n, count - 1) - prime * weighted_phi(n // prime, count - 1)

    def sum_primes(n: int) -> int:
        if n <= SIEVE_LIMIT:
            return prime_sum[n]
        square_root = isqrt(n)
        cube_root = _integer_cuberoot(n)
        first = prime_count[cube_root]
        last = prime_count[square_root]
        result = weighted_phi(n, first) + prime_sum[cube_root] - 1
        for index in range(first, last):
            prime = primes[index]
            quotient = n // prime
            result -= (sum_primes(quotient) - prime_sum[prime - 1]) * prime
        return result

    return sum_primes(value)
