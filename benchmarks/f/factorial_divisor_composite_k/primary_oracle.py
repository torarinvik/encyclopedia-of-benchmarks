"""Trial-factorization and quotient-sum reference for composite k | n!."""

from __future__ import annotations

UINT64_MAX = (1 << 64) - 1
MAX_N = 1_000_000_000_000
MIN_K = 4
MAX_K = 1_000_000


def _decode(n: int, k: int) -> tuple[int, int] | None:
    if (type(n) is not int or type(k) is not int
            or not 0 <= n <= UINT64_MAX or not 0 <= k <= UINT64_MAX
            or n > MAX_N or not MIN_K <= k <= MAX_K):
        return None
    return n, k


def _factor_trial(k: int) -> list[tuple[int, int]]:
    factors: list[tuple[int, int]] = []
    remaining = k
    divisor = 2
    while divisor <= remaining // divisor:
        if remaining % divisor == 0:
            exponent = 0
            while remaining % divisor == 0:
                remaining //= divisor
                exponent += 1
            factors.append((divisor, exponent))
        divisor += 1
    if remaining > 1:
        factors.append((remaining, 1))
    return factors


def _valuation_quotients(n: int, prime: int) -> int:
    total = 0
    quotient = n
    while quotient:
        quotient //= prime
        total += quotient
    return total


def expected_result(n: int, k: int) -> int:
    decoded = _decode(n, k)
    if decoded is None:
        return -1
    n, k = decoded
    factors = _factor_trial(k)
    if len(factors) == 1 and factors[0][1] == 1:
        return -1
    return min(_valuation_quotients(n, prime) // exponent
               for prime, exponent in factors)
