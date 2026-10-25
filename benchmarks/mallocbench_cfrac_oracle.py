"""Independent Python oracle for the bounded MallocBench CFRAC profile."""

from collections.abc import Sequence
from math import gcd, isqrt


MAX_BASE = 10
MAX_ITERATIONS = 48


def _prime_numbers(limit: int):
    for candidate in range(2, limit + 1):
        if all(candidate % divisor for divisor in range(2, isqrt(candidate) + 1)):
            yield candidate


def _modular_power(base: int, exponent: int, modulus: int) -> int:
    result = 1
    while exponent:
        if exponent & 1:
            result = result * base % modulus
        base = base * base % modulus
        exponent >>= 1
    return result


def _build_factor_base(n: int, count: int) -> list[int] | None:
    factors = [2]
    for prime in _prime_numbers(10_000):
        if prime == 2 or len(factors) == count:
            continue
        residue = _modular_power(n % prime, (prime - 1) // 2, prime)
        # Upstream selects Legendre residue zero; the bounded profile rejects it.
        if residue == 0:
            return None
        if residue == 1:
            factors.append(prime)
            if len(factors) == count:
                break
    return factors if len(factors) == count else None


def mallocbench_cfrac(values: Sequence[int] | None, length: int | None = None) -> int:
    if values is None:
        return -1
    if length is None:
        length = len(values)
    if length != 3 or len(values) < 3:
        return -1
    n, base_count, iteration_limit = values[:3]
    if not all(isinstance(value, int) for value in (n, base_count, iteration_limit)):
        return -1
    if not 15 <= n <= 1_000_000 or n % 2 == 0 or not 2 <= base_count <= MAX_BASE:
        return -1
    if not 1 <= iteration_limit <= MAX_ITERATIONS:
        return -1
    root = isqrt(n)
    if root * root == n:
        return -1
    factor_base = _build_factor_base(n, base_count)
    if factor_base is None:
        return -1

    # The relation basis maps each pivot bit to (parity row, relation subset).
    basis: dict[int, tuple[int, int]] = {}
    relation_rows: list[tuple[int, tuple[int, ...]]] = []
    u = previous_u = 2 * root
    quotient = 0
    denominator = 1
    previous_denominator = n - root * root
    numerator = 1
    previous_numerator = root
    sign = 0

    for _ in range(iteration_limit):
        old_numerator = numerator
        numerator = (quotient * numerator + previous_numerator) % n
        previous_numerator = old_numerator

        old_denominator = denominator
        denominator = quotient * (previous_u - u) + previous_denominator
        previous_denominator = old_denominator
        previous_u = u
        if denominator <= 0:
            return n

        quotient = 1
        remainder = u - denominator
        if remainder >= denominator:
            quotient, remainder = divmod(u, denominator)
        u = 2 * root - remainder
        sign ^= 1
        # The source terminates when this denominator repeats its Q=1 cycle.
        if denominator == 1:
            return n

        residual = denominator
        exponents: list[int] = []
        for prime in factor_base:
            exponent = 0
            while residual % prime == 0:
                residual //= prime
                exponent += 1
            exponents.append(exponent)
        if residual != 1:
            continue

        row = sign
        for index, exponent in enumerate(exponents):
            if exponent & 1:
                row |= 1 << (index + 1)
        relation_id = len(relation_rows)
        relation_rows.append((numerator, tuple(exponents)))
        subset = 1 << relation_id

        # Dictionary pivots are chosen by least significant set bit.
        while row:
            pivot = (row & -row).bit_length() - 1
            prior = basis.get(pivot)
            if prior is None:
                basis[pivot] = (row, subset)
                break
            row ^= prior[0]
            subset ^= prior[1]
        if row:
            continue

        x = 1
        exponent_totals = [0] * base_count
        for relation_id, (a_value, powers) in enumerate(relation_rows):
            if subset & (1 << relation_id):
                x = (x * a_value) % n
                for index, power in enumerate(powers):
                    exponent_totals[index] += power
        y = 1
        for prime, total in zip(factor_base, exponent_totals):
            y = (y * _modular_power(prime, total // 2, n)) % n
        for candidate in (gcd(abs(x - y), n), gcd(x + y, n)):
            if 1 < candidate < n:
                return candidate
    return n
