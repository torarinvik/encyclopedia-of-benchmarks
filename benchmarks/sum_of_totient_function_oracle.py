"""Independent bounded oracle for modular summatory Euler totients."""
from __future__ import annotations

from functools import lru_cache

MAX_N = 1_000_000_000
BASE_LIMIT = 100_000
MODULUS = 998_244_353
INVALID_RESULT = -1


@lru_cache(maxsize=1)
def _totient_prefix(limit: int) -> tuple[int, ...]:
    phi = list(range(limit + 1))
    for prime in range(2, limit + 1):
        if phi[prime] != prime:
            continue
        for multiple in range(prime, limit + 1, prime):
            phi[multiple] -= phi[multiple] // prime
    for value in range(1, limit + 1):
        phi[value] = (phi[value - 1] + phi[value]) % MODULUS
    return tuple(phi)


@lru_cache(maxsize=None)
def _summatory_phi(n: int) -> int:
    prefix = _totient_prefix(BASE_LIMIT)
    if n <= BASE_LIMIT:
        return prefix[n]

    def triangular_mod(value: int) -> int:
        left, right = value, value + 1
        if left % 2 == 0:
            left //= 2
        else:
            right //= 2
        return (left % MODULUS) * (right % MODULUS) % MODULUS

    answer = triangular_mod(n)
    left = 2
    while left <= n:
        quotient = n // left
        right = n // quotient
        block_size = right - left + 1
        answer = (answer - block_size * _summatory_phi(quotient)) % MODULUS
        left = right + 1
    return answer


def expected_result(value: int, algorithm: str = "sum_of_totient_function") -> int:
    if algorithm != "sum_of_totient_function" or type(value) is not int:
        return INVALID_RESULT
    if not 1 <= value <= MAX_N:
        return INVALID_RESULT

    return _summatory_phi(value)
