#!/usr/bin/env python3
"""Check two-input scalar ports through their C ABI and workload recorder."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from functools import lru_cache
import hashlib
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from uint53_xor_oracle import expected_result as uint53_xor_expected
from trinomial_triangle_oracle import expected_result as trinomial_triangle_oracle
from fermat_prime_checker_oracle import expected_result as fermat_prime_checker_oracle
from exponentiation_oracle import expected_result as exponentiation_oracle
from run_binary_scalar import encode_values

U64_MAX = 2**64 - 1
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
I32_MIN, I32_MAX = -(2**31), 2**31 - 1
ALGORITHMS = ("hamming_distance", "gcd", "lcm", "addition_without_arithmetic", "amicable_number", "ackermann", "range_bitwise_and", "first_bad_version", "problem56", "problem63", "problem74", "problem124", "problem174", "problem800", "uint53_xor", "modular_inverse_fermat_little_theorem", "modular_inverse_simple", "trinomial_triangle", "fermat_prime_checker", "exponentiation")
ALGORITHMS += ("arithmetic_left_shift", "arithmetic_right_shift", "unique_paths")
ALGORITHMS += ("circular_left_shift", "bitwise_addition_recursive", "first_different_bit", "count_number_of_one_bits", "highest_common_factor", "binary_pow", "imply_gate", "max_value", "min_value", "xor_swap_two_integers", "recursive_digit_sum", "binary_multiplication")

FERMAT_MAX_BASE = 1_000_000
FERMAT_MAX_MODULUS = 1_000_000


def modular_inverse_fermat_verifier_oracle(base: int, modulus: int) -> int:
    """Check primality by odd trial divisors, then use Python's modular pow."""
    if (type(base) is not int or type(modulus) is not int
            or not 1 <= base <= FERMAT_MAX_BASE
            or not 2 <= modulus <= FERMAT_MAX_MODULUS
            or base % modulus == 0):
        return -1
    if modulus != 2 and modulus % 2 == 0:
        return -1
    for divisor in range(3, math.isqrt(modulus) + 1, 2):
        if modulus % divisor == 0:
            return -1
    return pow(base, modulus - 2, modulus)


SIMPLE_INVERSE_MAX_X = 999
SIMPLE_INVERSE_MAX_Y = 1_000


def modular_inverse_simple_verifier_oracle(x: int, y: int) -> int:
    """Use modular arithmetic as an independent oracle for the iterative search."""
    if (type(x) is not int or type(y) is not int
            or not I64_MIN <= x <= I64_MAX or not I64_MIN <= y <= I64_MAX
            or not 1 <= x <= SIMPLE_INVERSE_MAX_X
            or not 2 <= y <= SIMPLE_INVERSE_MAX_Y
            or math.gcd(x, y) != 1):
        return -1
    return pow(x, -1, y)


def oracle(left: int, right: int) -> int:
    if type(left) is not int or type(right) is not int or not 0 <= left <= U64_MAX or not 0 <= right <= U64_MAX:
        raise ValueError("inputs must be unsigned 64-bit integers")
    return format(left ^ right, "064b").count("1")


def unique_paths_oracle(rows: int, columns: int) -> int:
    if (type(rows) is not int or type(columns) is not int
            or not 0 <= rows <= U64_MAX or not 0 <= columns <= U64_MAX):
        return -1
    if not 1 <= rows <= 34 or not 1 <= columns <= 34:
        return -1
    return math.comb(rows + columns - 2, rows - 1)


def gcd_oracle(left: int, right: int) -> int:
    if (type(left) is not int or type(right) is not int
            or not 0 <= left <= I64_MAX or not 0 <= right <= I64_MAX):
        raise ValueError("gcd inputs must be nonnegative signed 64-bit integers")
    if left == 0:
        return right
    if right == 0:
        return left
    common_shifts = 0
    while (left & 1) == 0 and (right & 1) == 0:
        left >>= 1
        right >>= 1
        common_shifts += 1
    while (left & 1) == 0:
        left >>= 1
    while right != 0:
        while (right & 1) == 0:
            right >>= 1
        if left > right:
            left, right = right, left
        right -= left
    return left << common_shifts


def lcm_oracle(left: int, right: int) -> int:
    if (type(left) is not int or type(right) is not int
            or not 0 <= left <= I64_MAX or not 0 <= right <= I64_MAX):
        raise ValueError("lcm inputs must be nonnegative signed 64-bit integers")
    if left == 0 or right == 0:
        return 0
    value = (left // gcd_oracle(left, right)) * right
    return value if value <= I64_MAX else -1


def addition_without_arithmetic_oracle(left: int, right: int) -> int:
    if (type(left) is not int or type(right) is not int
            or not I32_MIN <= left <= I32_MAX or not I32_MIN <= right <= I32_MAX):
        return -1
    total = left + right
    return total if I32_MIN <= total <= I32_MAX else -1


def range_bitwise_and_oracle(left: int, right: int) -> int:
    if (type(left) is not int or type(right) is not int
            or not 0 <= left <= right <= I32_MAX):
        return -1
    shift = 0
    while left != right:
        left >>= 1
        right >>= 1
        shift += 1
    return left << shift


def first_bad_version_oracle(version_count: int, first_bad: int) -> int:
    if (type(version_count) is not int or type(first_bad) is not int
            or not 1 <= version_count <= I32_MAX
            or not 1 <= first_bad <= version_count):
        return -1
    return first_bad


@lru_cache(maxsize=None)
def proper_divisor_sum_oracle(number: int) -> int:
    """Use the multiplicative divisor-sum identity, independent of divisor-pair scans."""
    if number <= 1:
        return 0
    remaining, sigma, factor = number, 1, 2
    while factor <= remaining // factor:
        if remaining % factor == 0:
            prime_power, term = 1, 1
            while remaining % factor == 0:
                remaining //= factor
                prime_power *= factor
                term += prime_power
            sigma *= term
        factor = 3 if factor == 2 else factor + 2
    if remaining > 1:
        sigma *= remaining + 1
    return sigma - number


def amicable_number_oracle(left: int, right: int) -> int:
    limit = 1_000_000_000
    if (type(left) is not int or type(right) is not int
            or not 1 <= left <= limit or not 1 <= right <= limit):
        return -1
    if left == right:
        return 0
    return int(proper_divisor_sum_oracle(left) == right
               and proper_divisor_sum_oracle(right) == left)


@lru_cache(maxsize=None)
def _ackermann_value(m: int, n: int) -> int:
    if m == 0:
        return n + 1
    if n == 0:
        return _ackermann_value(m - 1, 1)
    return _ackermann_value(m - 1, _ackermann_value(m, n - 1))


def ackermann_oracle(m: int, n: int) -> int:
    if (type(m) is not int or type(n) is not int
            or not I64_MIN <= m <= I64_MAX or not I64_MIN <= n <= I64_MAX
            or not 0 <= m <= 3 or not 0 <= n <= 5):
        return -1
    return _ackermann_value(m, n)


def problem56_digit_sum_oracle(a: int, b: int) -> int:
    if (type(a) is not int or type(b) is not int or not 1 <= a <= 200 or not 1 <= b <= 200):
        return -1
    return max(sum(map(int, str(base ** power)))
               for base in range(a) for power in range(b))


@lru_cache(maxsize=8)
def problem800_source_count(base: int, degree: int) -> int:
    """Find each right boundary by binary search instead of the ports' pointer scan."""
    if (type(base) is not int or type(degree) is not int
            or not 2 <= base <= 1_000_000 or not 1 <= degree <= 1_000_000):
        return -1
    upper_bound = degree * math.log2(base)
    max_prime = int(upper_bound)
    if max_prime <= 2:
        return 0
    sieve = bytearray([1]) * max_prime
    sieve[0:2] = b"\x00\x00"
    for prime in range(2, math.isqrt(max_prime - 1) + 1):
        if sieve[prime]:
            for multiple in range(prime * prime, max_prime, prime):
                sieve[multiple] = 0
    primes = [value for value in range(2, max_prime) if sieve[value]]
    left, right, count = 0, len(primes) - 1, 0
    while left < right:
        left_prime = primes[left]

        def score(rank: int) -> float:
            right_prime = primes[rank]
            return (right_prime * math.log2(left_prime)
                    + left_prime * math.log2(right_prime))

        if score(right) > upper_bound:
            low, high = 0, right
            while low < high:
                middle = (low + high + 1) // 2
                if score(middle) <= upper_bound:
                    low = middle
                else:
                    high = middle - 1
            right = low
        count += right - left
        left += 1
    return count


def problem63_powerful_digit_count(max_base: int, max_power: int) -> int:
    if (type(max_base) is not int or type(max_power) is not int
            or not I64_MIN <= max_base <= I64_MAX or not I64_MIN <= max_power <= I64_MAX):
        return -1
    # Decimal-string lengths are exact; source bounds above these caps cannot contribute.
    return sum(len(str(base ** power)) == power
               for base in range(1, min(max_base, 10))
               for power in range(1, min(max_power, 22)))


def problem74_chain_count(num_terms: int, max_start: int) -> int:
    if max_start > 1_000_000:
        return -1
    if max_start <= 1:
        return 0
    digit_factorials = (1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880)
    memo = {145: 0, 169: 3, 36301: 3, 1454: 3, 871: 2, 45361: 2, 872: 2}

    def digit_factorial_sum(value: int) -> int:
        total = 0
        while value:
            total += digit_factorials[value % 10]
            value //= 10
        return total or 1

    count = 0
    for start in range(1, max_start):
        path: list[int] = []
        position: dict[int, int] = {}
        current = start
        while current not in memo:
            following = digit_factorial_sum(current)
            if following in position:
                # The source caches the current node as length zero, then
                # unwinds only the preceding path nodes.
                memo[current] = 0
                length = 0
                break
            position[current] = len(path)
            path.append(current)
            current = following
        else:
            length = memo[current]
        for value in reversed(path):
            length += 1
            memo[value] = length
        count += memo[start] == num_terms
    return count


@lru_cache(maxsize=16)
def problem124_radical_order(n_max: int, rank: int) -> int:
    """Order by trial-factored radicals, independently of the ports' sieve buckets."""
    if not 1 <= rank <= n_max <= 100_000:
        return -1

    def radical(value: int) -> int:
        result = 1
        factor = 2
        while factor <= value // factor:
            if value % factor == 0:
                result *= factor
                while value % factor == 0:
                    value //= factor
            factor = 3 if factor == 2 else factor + 2
        if value > 1:
            result *= value
        return result

    ordered = sorted((radical(value), value) for value in range(1, n_max + 1))
    return ordered[rank - 1][1]


@lru_cache(maxsize=8)
def problem174_lamina_counts(t_limit: int, n_limit: int) -> int:
    """Count factor-pair representations, independently of the outer-width scan."""
    if (type(t_limit) is not int or type(n_limit) is not int
            or not I64_MIN <= t_limit <= I64_MAX
            or not I64_MIN <= n_limit <= I64_MAX
            or t_limit > 1_000_000):
        return -1
    if t_limit < 0:
        return 0
    if t_limit <= 1:
        return 0
    counts = [0] * (t_limit + 1)
    for difference in range(2, math.isqrt(t_limit - 1) + 1, 2):
        for total_width in range(difference + 2, t_limit // difference + 1, 2):
            counts[difference * total_width] += 1
    return sum(1 <= representations <= n_limit for representations in counts)


def result(algorithm: str, left: int, right: int) -> int:
    if algorithm == "binary_multiplication":
        if not 0 <= left <= 1_000_000_000 or not 0 <= right <= 1_000_000_000:
            raise ValueError("binary_multiplication oracle inputs must lie within the declared 0..1e9 domain")
        return left * right
    if algorithm == "unique_paths":
        return unique_paths_oracle(left, right)
    if algorithm == "circular_left_shift":
        if not 0 <= left <= (1 << 53) - 1 or not 0 <= right <= 53:
            return -1
        rotation = right % 53
        mask = (1 << 53) - 1
        return ((left << rotation) | (left >> (53 - rotation))) & mask
    if algorithm in {"arithmetic_left_shift", "arithmetic_right_shift"}:
        if not 0 <= left <= (1 << 53) - 1 or not 0 <= right <= 53:
            return -1
        if algorithm == "arithmetic_left_shift":
            return (left << right) & ((1 << 53) - 1)
        msb = left >> 52
        fill = ((1 << right) - 1) << (53 - right)
        return (left >> right) | (fill if msb else 0)
    if algorithm == "bitwise_addition_recursive":
        if not 0 <= left <= I32_MAX or not 0 <= right <= I32_MAX:
            return -1
        return left + right
    if algorithm == "first_different_bit":
        if not I32_MIN <= left <= I32_MAX or not I32_MIN <= right <= I32_MAX:
            return -1
        difference = (left & 0xFFFFFFFF) ^ (right & 0xFFFFFFFF)
        return 32 if difference == 0 else (difference & -difference).bit_length() - 1
    if algorithm == "count_number_of_one_bits":
        if not 0 <= left <= 0xFFFFFFFF or not 0 <= right <= 2:
            return -1
        return bin(left).count("1")
    if algorithm == "highest_common_factor":
        if not 0 <= left <= 64 or not 0 <= right <= 64:
            raise ValueError("highest_common_factor oracle inputs must lie within the declared 0..64 domain")
        return math.gcd(left, right)
    if algorithm == "binary_pow":
        if not I32_MIN <= left <= I32_MAX or not I32_MIN <= right <= I32_MAX:
            return -2_147_483_649
        wrapped = pow(left & 0xFFFFFFFF, right, 1 << 32) if right > 0 else 1
        return wrapped - (1 << 32) if wrapped >= (1 << 31) else wrapped
    if algorithm == "imply_gate":
        if left not in (0, 1) or right not in (0, 1):
            return -1
        return int(left == 0 or right == 1)
    if algorithm in {"max_value", "min_value"}:
        if not I32_MIN <= left <= I32_MAX or not I32_MIN <= right <= I32_MAX:
            return -1
        return max(left, right) if algorithm == "max_value" else min(left, right)
    if algorithm == "xor_swap_two_integers":
        if not -32768 <= left <= 32767 or not -32768 <= right <= 32767:
            return -1
        return (right + 32768) * 65536 + (left + 32768)
    if algorithm == "recursive_digit_sum":
        if not 0 <= left <= I64_MAX or not 0 <= right <= 1_000_000:
            return -1
        digit_total = sum(int(digit) for digit in str(left)) * right
        return 0 if digit_total == 0 else 1 + (digit_total - 1) % 9
    if algorithm == "uint53_xor":
        return uint53_xor_expected(left, right)
    if algorithm == "problem124":
        return problem124_radical_order(left, right)
    if algorithm == "problem800":
        return problem800_source_count(left, right)
    if algorithm == "problem174":
        return problem174_lamina_counts(left, right)
    if algorithm == "modular_inverse_fermat_little_theorem":
        return modular_inverse_fermat_verifier_oracle(left, right)
    if algorithm == "modular_inverse_simple":
        return modular_inverse_simple_verifier_oracle(left, right)
    if algorithm == "fermat_prime_checker":
        return fermat_prime_checker_oracle((left, right))
    if algorithm == "exponentiation":
        return exponentiation_oracle((left, right))
    if algorithm == "hamming_distance":
        return oracle(left, right)
    if algorithm == "gcd":
        return gcd_oracle(left, right)
    if algorithm == "lcm":
        return lcm_oracle(left, right)
    if algorithm == "addition_without_arithmetic":
        return addition_without_arithmetic_oracle(left, right)
    if algorithm == "amicable_number":
        return amicable_number_oracle(left, right)
    if algorithm == "ackermann":
        return ackermann_oracle(left, right)
    if algorithm == "range_bitwise_and":
        return range_bitwise_and_oracle(left, right)
    if algorithm == "first_bad_version":
        return first_bad_version_oracle(left, right)
    if algorithm == "problem56":
        return problem56_digit_sum_oracle(left, right)
    if algorithm == "problem63":
        return problem63_powerful_digit_count(left, right)
    if algorithm == "problem74":
        if (type(left) is not int or type(right) is not int
                or not I64_MIN <= left <= I64_MAX or not I64_MIN <= right <= I64_MAX):
            return -1
        return problem74_chain_count(left, right)
    if algorithm == "trinomial_triangle":
        return trinomial_triangle_oracle(left, right)
    raise ValueError(f"no independent oracle for {algorithm}")


def corpus(algorithm: str, workload: dict) -> tuple[str, int]:
    pairs = {tuple(case["input_values"]) for case in workload["cases"]}
    if algorithm == "modular_inverse_fermat_little_theorem":
        prime_moduli = (2, 3, 5, 7, 11, 13, 17, 19, 23, 31, 97, 101, 997, 999983)
        for modulus in prime_moduli:
            for base in (1, 2, modulus - 1, modulus, modulus + 1, FERMAT_MAX_BASE):
                if 1 <= base <= FERMAT_MAX_BASE:
                    pairs.add((base, modulus))
        composite_moduli = (4, 8, 9, 15, 25, 27, 35, 49, 100, 999984, FERMAT_MAX_MODULUS)
        for modulus in composite_moduli:
            for base in (1, 2, modulus - 1, modulus, FERMAT_MAX_BASE):
                if 1 <= base <= FERMAT_MAX_BASE:
                    pairs.add((base, modulus))
        pairs.update({(0, 7), (-1, 7), (FERMAT_MAX_BASE + 1, 7),
                      (3, 0), (3, 1), (3, -2), (3, FERMAT_MAX_MODULUS + 1),
                      (I64_MIN, 7), (I64_MAX, 7), (3, I64_MIN), (3, I64_MAX)})
        rng = random.Random(20261016)
        pairs.update((rng.randint(1, FERMAT_MAX_BASE), rng.choice(prime_moduli))
                     for _ in range(256))
    elif algorithm == "exponentiation":
        pairs.update((base, exponent) for base in range(0, 32) for exponent in range(0, 8))
        pairs.update({(255, 7), (255, 0), (0, 0), (256, 1), (-1, 1), (1, 8),
                      (I64_MIN, 0), (I64_MAX, 1)})
    elif algorithm == "fermat_prime_checker":
        pairs.update((number, rounds) for number in range(2, 100) for rounds in (2, 3, 5, 8, 16))
        pairs.update({(2, 64), (3, 64), (97, 64), (561, 64), (341, 64),
                      (999983, 64), (1000000, 64), (1, 4), (1000001, 4),
                      (97, 0), (97, 1), (97, 65), (-1, 4),
                      (I64_MIN, 4), (I64_MAX, 4)})
        rng = random.Random(20261016)
        pairs.update((rng.randint(2, 1_000_000), rng.randint(2, 64)) for _ in range(256))
    elif algorithm == "modular_inverse_simple":
        pairs.update((x, y) for x in range(1, 33) for y in range(2, 33))
        pairs.update({
            (1, 2), (1, SIMPLE_INVERSE_MAX_Y), (SIMPLE_INVERSE_MAX_X, SIMPLE_INVERSE_MAX_Y),
            (SIMPLE_INVERSE_MAX_X, SIMPLE_INVERSE_MAX_Y - 1),
            (SIMPLE_INVERSE_MAX_X - 1, SIMPLE_INVERSE_MAX_Y - 1),
            (0, 7), (-1, 7), (SIMPLE_INVERSE_MAX_X + 1, 997),
            (3, 0), (3, 1), (3, SIMPLE_INVERSE_MAX_Y + 1),
            (6, 9), (8, 4), (I64_MIN, 7), (I64_MAX, 7),
            (3, I64_MIN), (3, I64_MAX),
        })
        rng = random.Random(20261016)
        pairs.update((rng.randint(1, SIMPLE_INVERSE_MAX_X),
                      rng.randint(2, SIMPLE_INVERSE_MAX_Y))
                     for _ in range(256))
    elif algorithm == "problem56":
        pairs.update({(1, 1), (2, 2), (10, 10), (100, 100), (100, 200), (200, 1), (1, 200),
                      (200, 200), (0, 1), (1, 0), (201, 1), (1, 201), (-1, 10), (10, -1)})
        rng = random.Random(20261015)
        pairs.update((rng.randrange(1, 31), rng.randrange(1, 31)) for _ in range(64))
    elif algorithm == "problem63":
        pairs.update({(0, 0), (1, 1), (2, 2), (10, 22), (11, 22), (10, 23),
                      (100, 100), (-1, -1), (I64_MIN, I64_MIN), (I64_MAX, I64_MAX),
                      (I64_MIN, 22), (10, I64_MAX)})
        rng = random.Random(20261015)
        pairs.update((rng.randrange(-2, 15), rng.randrange(-2, 28)) for _ in range(64))
    elif algorithm == "problem74":
        pairs.update({(60, 1_000_000), (10, 1000), (0, 146), (0, 145),
                      (1, 2), (60, 1), (-1, 100), (1000, 100),
                      (60, 0), (60, -1), (60, 1_000_001),
                      (I64_MIN, I64_MIN), (I64_MAX, I64_MAX)})
        rng = random.Random(20261015)
        pairs.update((rng.randrange(-2, 100), rng.randrange(-2, 5000)) for _ in range(32))
    elif algorithm == "problem800":
        pairs.update({(2, 1), (2, 5), (2, 20), (3, 4), (800, 1), (800, 800),
                      (1, 800), (800, 0), (1_000_001, 1), (2, 1_000_001),
                      (I64_MIN, I64_MAX), (I64_MAX, I64_MAX)})
        rng = random.Random(20261015)
        pairs.update((rng.randrange(2, 1001), rng.randrange(1, 1001)) for _ in range(96))
    elif algorithm == "problem174":
        pairs.update({(-1, 10), (0, 10), (7, 10), (8, 1), (32, 2),
                      (1000, 5), (1000, 10), (10000, 10),
                      (1000001, 10), (I64_MIN, I64_MAX), (I64_MAX, I64_MAX)})
        rng = random.Random(20261015)
        pairs.update((rng.randrange(-2, 2000), rng.randrange(-2, 13)) for _ in range(64))
    elif algorithm in {"arithmetic_left_shift", "arithmetic_right_shift", "circular_left_shift"}:
        numbers = (0, 1, 2, (1 << 52) - 1, 1 << 52,
                   (1 << 53) - 2, (1 << 53) - 1, 1 << 53, -1)
        shifts = (0, 1, 2, 51, 52, 53, 54, -1, I64_MIN, I64_MAX)
        pairs.update((number, shift) for number in numbers for shift in shifts)
        rng = random.Random(20261016)
        pairs.update((rng.randrange(1 << 53), rng.randrange(54)) for _ in range(512))
    elif algorithm == "bitwise_addition_recursive":
        edge_values = (-1, 0, 1, 2, I32_MAX - 1, I32_MAX, I32_MAX + 1, I64_MIN, I64_MAX)
        pairs.update((left, right) for left in edge_values for right in edge_values)
        rng = random.Random(20261016)
        pairs.update((rng.randrange(-1, I32_MAX + 2), rng.randrange(-1, I32_MAX + 2))
                     for _ in range(512))
    elif algorithm == "first_different_bit":
        edge_values = (I64_MIN, I32_MIN - 1, I32_MIN, -1, 0, 1, I32_MAX, I32_MAX + 1, I64_MAX)
        pairs.update((left, right) for left in edge_values for right in edge_values)
        rng = random.Random(20261016)
        pairs.update((rng.randrange(I32_MIN, I32_MAX + 1),
                      rng.randrange(I32_MIN, I32_MAX + 1)) for _ in range(512))
    elif algorithm == "count_number_of_one_bits":
        numbers = (I64_MIN, -1, 0, 1, 2, 3, 0x55555555, 0xAAAAAAAA,
                   0x80000000, 0xFFFFFFFF, 0x100000000, I64_MAX, U64_MAX)
        methods = (I64_MIN, -1, 0, 1, 2, 3, I64_MAX)
        pairs.update((number, method) for number in numbers for method in methods)
        rng = random.Random(20261016)
        pairs.update((rng.getrandbits(32), rng.randrange(3)) for _ in range(512))
        pairs.update((rng.getrandbits(32), rng.choice((-1, 3))) for _ in range(128))
    elif algorithm == "highest_common_factor":
        pairs.update((left, right) for left in range(65) for right in range(65))
    elif algorithm == "binary_multiplication":
        boundary_values = (0, 1, 2, 999_999_999, 1_000_000_000)
        pairs.update((left, right) for left in boundary_values for right in boundary_values)
        rng = random.Random(20261016)
        pairs.update((rng.randrange(1_000_000_001), rng.randrange(1_000_000_001))
                     for _ in range(512))
    elif algorithm == "binary_pow":
        base_edges = (I64_MIN, I32_MIN - 1, I32_MIN, -46341, -2, -1,
                      0, 1, 2, 3, 46341, I32_MAX, I32_MAX + 1, I64_MAX)
        exponent_edges = (I64_MIN, I32_MIN, -3, -1, 0, 1, 2, 3, 31, 32, 33,
                          63, 64, I32_MAX, I32_MAX + 1, I64_MAX)
        pairs.update((base, exponent) for base in base_edges for exponent in exponent_edges)
        rng = random.Random(20261016)
        pairs.update((rng.randrange(I32_MIN, I32_MAX + 1),
                      rng.randrange(I32_MIN, I32_MAX + 1)) for _ in range(512))
    elif algorithm == "imply_gate":
        edge_values = (I64_MIN, -1, 0, 1, 2, I64_MAX, U64_MAX)
        pairs.update((left, right) for left in edge_values for right in edge_values)
    elif algorithm in {"max_value", "min_value"}:
        edge_values = (I64_MIN, I32_MIN - 1, I32_MIN, -1, 0, 1,
                       I32_MAX, I32_MAX + 1, I64_MAX)
        pairs.update((left, right) for left in edge_values for right in edge_values)
        rng = random.Random(20261016)
        pairs.update((rng.randrange(I32_MIN, I32_MAX + 1),
                      rng.randrange(I32_MIN, I32_MAX + 1)) for _ in range(512))
    elif algorithm == "xor_swap_two_integers":
        edge_values = (I64_MIN, -32769, -32768, -1, 0, 1, 32767, 32768, I64_MAX)
        pairs.update((left, right) for left in edge_values for right in edge_values)
        rng = random.Random(20261016)
        pairs.update((rng.randrange(-32768, 32768), rng.randrange(-32768, 32768))
                     for _ in range(512))
    elif algorithm == "recursive_digit_sum":
        number_edges = (I64_MIN, -1, 0, 1, 9, 10, 99, I64_MAX)
        repetition_edges = (I64_MIN, -1, 0, 1, 2, 3, 999_999, 1_000_000, 1_000_001, I64_MAX)
        pairs.update((number, repetitions)
                     for number in number_edges for repetitions in repetition_edges)
        rng = random.Random(20261016)
        pairs.update((rng.randrange(I64_MAX + 1), rng.randrange(1_000_001)) for _ in range(512))
    elif algorithm == "unique_paths":
        pairs.update((rows, columns) for rows in range(37) for columns in range(37))
        edge_values = [0, 1, 2, 33, 34, 35, 36, U64_MAX - 1, U64_MAX]
        pairs.update((rows, columns) for rows in edge_values for columns in edge_values)
        rng = random.Random(20261015)
        pairs.update((rng.getrandbits(64), rng.getrandbits(64)) for _ in range(512))
    elif algorithm == "ackermann":
        pairs.update((m, n) for m in range(4) for n in range(6))
        left_edges = [I64_MIN, -1, 0, 1, 3, 4, I64_MAX]
        right_edges = [I64_MIN, -1, 0, 1, 5, 6, I64_MAX]
        pairs.update((left, right) for left in left_edges for right in right_edges)
        rng = random.Random(20261014)
        pairs.update((rng.randrange(-1, 5), rng.randrange(-1, 7)) for _ in range(512))
    elif algorithm == "range_bitwise_and":
        pairs.update((left, right) for left in range(256) for right in range(256))
        edge_values = sorted({0, 1, 2, 3, 7, 8, 15, 16, 31, 32, 63, 64,
                              127, 128, 255, 256, 1023, 1024,
                              *(2**bit + delta for bit in range(1, 31) for delta in (-1, 0, 1)),
                              I32_MAX - 2, I32_MAX - 1, I32_MAX, I32_MAX + 1})
        pairs.update((left, right) for left in edge_values for right in edge_values)
        rng = random.Random(20261015)
        for _ in range(1024):
            left = rng.randrange(0, I32_MAX + 2)
            right = rng.randrange(0, I32_MAX + 2)
            pairs.add((min(left, right), max(left, right)))
            pairs.add((left, right))
    elif algorithm == "first_bad_version":
        pairs = set()
        for version_count in range(1, 129):
            pairs.update((version_count, first_bad)
                         for first_bad in range(1, version_count + 1))
            pairs.add((version_count, 0))
            pairs.add((version_count, version_count + 1))
        edge_counts = [1, 2, 3, 4, 7, 8, 2**30 - 1, 2**30,
                       I32_MAX - 1, I32_MAX, I32_MAX + 1, U64_MAX]
        for version_count in edge_counts:
            edge_bad_values = {0, 1, 2, version_count // 2,
                               version_count // 2 + 1, version_count,
                               version_count + 1, U64_MAX}
            edge_bad_values = {value for value in edge_bad_values if value <= U64_MAX}
            pairs.update((version_count, first_bad) for first_bad in edge_bad_values)
    elif algorithm == "trinomial_triangle":
        pairs.update((n, k) for n in range(11) for k in range(-10, 11))
        pairs.update({(-1, 0), (11, 0), (10, -11), (10, 11),
                      (I64_MIN, 0), (I64_MAX, 0), (0, I64_MIN), (0, I64_MAX)})
    elif algorithm != "problem56":
        pairs.update((left, right) for left in range(256) for right in range(256))
    if algorithm == "problem124":
        pairs.update((n_max, rank) for n_max in range(1, 31) for rank in range(1, n_max + 1))
        pairs.update({(0, 0), (0, 1), (1, 0), (10, 11), (100_001, 1),
                      (-1, 1), (1, -1), (I64_MIN, I64_MIN), (I64_MAX, I64_MAX)})
    if algorithm not in {"ackermann", "problem56", "problem63", "problem74", "problem124", "problem174", "problem800", "modular_inverse_fermat_little_theorem", "modular_inverse_simple", "trinomial_triangle", "fermat_prime_checker", "exponentiation", "arithmetic_left_shift", "arithmetic_right_shift", "unique_paths", "circular_left_shift", "bitwise_addition_recursive", "first_different_bit", "count_number_of_one_bits", "highest_common_factor", "binary_pow", "imply_gate", "max_value", "min_value", "xor_swap_two_integers", "recursive_digit_sum", "binary_multiplication"}:
        if algorithm == "range_bitwise_and":
            edge_values = [0, 1, 2, 3, 7, 8, 15, 16, 2**30 - 1, 2**30,
                           I32_MAX - 1, I32_MAX, I32_MAX + 1, U64_MAX]
            random_bits = 32
        elif algorithm == "first_bad_version":
            edge_values = [0, 1, 2, 3, I32_MAX - 1, I32_MAX, I32_MAX + 1, U64_MAX]
            random_bits = 32
        elif algorithm == "uint53_xor":
            edge_values = [0, 1, 2, 3, 1 << 26, 1 << 52,
                           0x15555555555555, 0x0AAAAAAAAAAAAA,
                           9_007_199_254_740_991]
            random_bits = 53
        elif algorithm == "hamming_distance":
            edge_values = [0, 1, 2**63, U64_MAX, 0xAAAAAAAAAAAAAAAA, 0x5555555555555555]
            random_bits = 64
        elif algorithm == "addition_without_arithmetic":
            edge_values = [I32_MIN - 1, I32_MIN, I32_MIN + 1, -1, 0, 1,
                           I32_MAX - 1, I32_MAX, I32_MAX + 1]
            random_bits = 32
        elif algorithm == "amicable_number":
            edge_values = [0, 1, 2, 3, 6, 28, 220, 284, 1184, 1210,
                           2620, 2924, 5020, 5564, 6232, 6368,
                           999_999, 1_000_000, 999_999_999, 1_000_000_000,
                           1_000_000_001]
            random_bits = 30
        else:
            edge_values = [0, 1, 2, 3, I64_MAX, I64_MAX - 1, 7540113804746346429, 4660046610375530309]
            random_bits = 63
        pairs.update((left, right) for left in edge_values for right in edge_values)
        rng = random.Random(20261014)
        if algorithm == "uint53_xor":
            pairs.update({(-1, 0), (0, -1), (9_007_199_254_740_992, 0),
                          (0, 9_007_199_254_740_992), (I64_MIN, I64_MAX)})
        elif algorithm == "range_bitwise_and":
            pairs.update((left, right) for left, right in ((I32_MAX + 1, I32_MAX + 1),
                                                            (0, U64_MAX), (I32_MAX, 0)))
        elif algorithm == "addition_without_arithmetic":
            pairs.update((rng.randrange(I32_MIN - 1, I32_MAX + 2),
                          rng.randrange(I32_MIN - 1, I32_MAX + 2)) for _ in range(512))
        elif algorithm == "amicable_number":
            pairs.update((rng.randrange(1, 1_000_000_001),
                          rng.randrange(1, 1_000_000_001)) for _ in range(128))
        elif algorithm == "first_bad_version":
            for _ in range(512):
                version_count = rng.randrange(1, I32_MAX + 1)
                if rng.randrange(4) == 0:
                    first_bad = rng.choice([0, version_count + 1])
                else:
                    first_bad = rng.randrange(1, version_count + 1)
                pairs.add((version_count, first_bad))
        else:
            pairs.update((rng.getrandbits(random_bits), rng.getrandbits(random_bits)) for _ in range(512))
    for case in workload["cases"]:
        left, right, expected = encode_values(case, algorithm)
        if expected != result(algorithm, left, right):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
    data = "".join(
        f"{left if left >= 0 else left + (1 << 64)} "
        f"{right if right >= 0 else right + (1 << 64)} "
        f"{result(algorithm, left, right)}\n"
        for left, right in sorted(pairs)
    )
    return data, len(pairs)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="binary_scalar")
    checker = manifest["binaries"]["binary_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=90)
    if checked.returncode:
        raise RuntimeError(f"binary C ABI correctness check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_binary_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=90)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        left, right, expected = encode_values(case, algorithm)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != [left, right]
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/binary_scalar")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages) or len(set(args.algorithms)) != len(args.algorithms):
        parser.error("jobs must be positive and algorithm/language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workloads = {}
    corpora = {}
    corpus_paths = {}
    for algorithm in args.algorithms:
        workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
        workloads[algorithm] = json.loads(workload_path.read_text(encoding="utf-8"))
        corpora[algorithm] = corpus(algorithm, workloads[algorithm])
        corpus_paths[algorithm] = directory / f"{algorithm}-corpus.txt"
        corpus_paths[algorithm].write_text(corpora[algorithm][0], encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm in args.algorithms:
            data, case_count = corpora[algorithm]
            workload = workloads[algorithm]
            for language in args.languages:
                job = executor.submit(verify, algorithm, language,
                                      directory / algorithm[0] / algorithm / language,
                                      args.elisa_compiler, data, case_count, workload)
                jobs[job] = (algorithm, language)
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
                print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle pairs, "
                      f"{result['workload_records']} workload records", flush=True)
            except Exception as error:
                result = {"algorithm": algorithm, "language": language, "status": "failed", "error": str(error)}
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
            results.append(result)
    report = {"checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "algorithms": args.algorithms, "languages": args.languages,
              "host": {"os": platform.system(), "architecture": platform.machine()},
              "all_passed": all(result["status"] == "passed" for result in results),
              "corpora": {algorithm: {"path": str(corpus_paths[algorithm]),
                                      "sha256": hashlib.sha256(corpora[algorithm][0].encode()).hexdigest()}
                          for algorithm in args.algorithms},
              "verification_source_sha256": sha256_file(Path(__file__)),
              "compiler_recipes_sha256": sha256_file(ROOT / "benchmarks/build_abi.py"),
              "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_binary_scalar.py"),
              "result_schema_sha256": sha256_file(ROOT / "benchmarks/results.schema.json"),
              "workloads": {algorithm: sha256_file(ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json")
                            for algorithm in args.algorithms},
              "results": sorted(results, key=lambda result: (result["algorithm"], result["language"]))}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
