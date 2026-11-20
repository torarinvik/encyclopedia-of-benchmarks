"""Prime-candidate factorization and digit-sum valuation reference."""

from __future__ import annotations

UINT64_MAX = (1 << 64) - 1
MAX_N = 1_000_000_000_000
MIN_K = 4
MAX_K = 1_000_000


def _prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def _factor_by_prime_candidates(k: int) -> tuple[list[tuple[int, int]], bool]:
    remaining = k
    factors: list[tuple[int, int]] = []
    found_factor = False
    candidate = 2
    while candidate * candidate <= k:
        if _prime(candidate) and k % candidate == 0:
            found_factor = True
            exponent = 0
            while remaining % candidate == 0:
                remaining //= candidate
                exponent += 1
            factors.append((candidate, exponent))
        candidate += 1
    if remaining > 1:
        factors.append((remaining, 1))
    return factors, found_factor


def _valuation_digit_sum(n: int, prime: int) -> int:
    remaining = n
    digit_sum = 0
    while remaining:
        remaining, digit = divmod(remaining, prime)
        digit_sum += digit
    return (n - digit_sum) // (prime - 1)


def expected_result(n: int, k: int) -> int:
    if (type(n) is not int or type(k) is not int
            or not 0 <= n <= UINT64_MAX or not 0 <= k <= UINT64_MAX
            or n > MAX_N or not MIN_K <= k <= MAX_K):
        return -1
    factors, found_factor = _factor_by_prime_candidates(k)
    if not found_factor:
        return -1
    return min(_valuation_digit_sum(n, prime) // exponent
               for prime, exponent in factors)
