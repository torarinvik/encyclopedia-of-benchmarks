#!/usr/bin/env python3
"""Build and check the reviewed scalar algorithms against independent oracles."""

from __future__ import annotations

import argparse
from array import array
from bisect import bisect_left, bisect_right
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from fractions import Fraction
from decimal import Context, Decimal, localcontext
from functools import lru_cache
import hashlib
from itertools import combinations_with_replacement, permutations, product
import json
import math
from pathlib import Path
import platform
import random
import shlex
import subprocess
import sys

from build_scalar import EXTENSIONS, ROOT, build, sha256_file
from binary_length_oracle import MAX_INPUT as MAX_BINARY_LENGTH_INPUT
from binary_length_oracle import expected_result as binary_length_oracle
from gauss_easter_oracle import MAX_YEAR as MAX_GAUSS_EASTER_YEAR
from gauss_easter_oracle import MIN_YEAR as MIN_GAUSS_EASTER_YEAR
from gauss_easter_oracle import expected_result as gauss_easter_oracle
from leap_year_oracle import expected_result as leap_year_oracle
from liouville_oracle import MAX_INPUT as MAX_LIOUVILLE_INPUT
from liouville_oracle import expected_result as liouville_oracle
from parity_oracle import check_even as check_even_oracle
from parity_oracle import is_odd as is_odd_oracle
from scalar_sequence_oracles import MAX_CUBES_SEQUENCE_INDEX
from scalar_sequence_oracles import all_ones_sequence as all_ones_sequence_oracle
from scalar_sequence_oracles import all_threes_sequence as all_threes_sequence_oracle
from scalar_sequence_oracles import all_twos_sequence as all_twos_sequence_oracle
from scalar_sequence_oracles import cubes_sequence as cubes_sequence_oracle
from simple_scalar_oracles import MAX_CARMICHAEL_INPUT, MAX_KEITH_INPUT, MAX_KYNEA_INDEX
from simple_scalar_oracles import MAX_PADOVAN_INDEX, MAX_PELL_INDEX, MAX_PERRIN_INDEX
from simple_scalar_oracles import MAX_SMITH_INPUT, MAX_SPHENIC_INPUT
from simple_scalar_oracles import MAX_SIGNED_INT64
from simple_scalar_oracles import carmichael_number as carmichael_number_oracle
from simple_scalar_oracles import clear_leftmost_set_bit as clear_leftmost_set_bit_oracle
from simple_scalar_oracles import clear_lowest_set_bit as clear_lowest_set_bit_oracle
from simple_scalar_oracles import count_leading_zeros as count_leading_zeros_oracle
from simple_scalar_oracles import count_set_bits as count_set_bits_oracle
from simple_scalar_oracles import evil_number as evil_number_oracle
from simple_scalar_oracles import keith_number as keith_number_oracle
from simple_scalar_oracles import kynea_numbers as kynea_numbers_oracle
from simple_scalar_oracles import padovan_sequence as padovan_sequence_oracle
from simple_scalar_oracles import pell_number as pell_number_oracle
from simple_scalar_oracles import perrin_number as perrin_number_oracle
from simple_scalar_oracles import smith_number as smith_number_oracle
from simple_scalar_oracles import sphenic_number as sphenic_number_oracle
from simple_scalar_oracles import sum_of_odd_numbers as sum_of_odd_numbers_oracle
from problem12_sol1_oracle import expected_result as problem12_sol1_oracle
from sum_multiples_inclusion_exclusion_oracle import expected_result as sum_multiples_inclusion_exclusion_oracle
from twos_complement_of_binary_oracle import expected_result as twos_complement_of_binary_oracle
from magic_square_oracle import expected_result as magic_square_oracle
from mersenne_primes_oracle import expected_result as mersenne_primes_oracle
from trial_division_factorizer_oracle import expected_result as trial_division_factorizer_oracle

ALGORITHMS = ("factorial", "check_factorial", "factorial_trailing_zeroes", "binary_count_trailing_zeros", "trailing_zeroes", "fibonacci", "tribonacci", "bitwise_complement", "aliquot_sum", "sum_of_divisors", "abundant_number", "armstrong_number", "lcm_sum", "leonardo_number", "signum", "is_even", "double_factorial", "power_of_two", "prime_check", "perfect_number", "catalan_number", "bell_numbers", "number_of_digits", "digital_root", "happy_number", "automorphic_number", "isautomorphic", "palindrome_number", "power_of_four", "fibonacci_fast", "lucas_series", "lucas_series_recursive", "hamming_weight", "reverse_bits", "collatz", "problem1", "problem2", "problem3", "problem4", "problem5", "problem6", "problem7", "problem8", "problem9", "problem10", "problem10_ruby_prefix", "problem11_sol1", "problem12", "problem12_sol1", "problem13", "problem14", "problem15", "problem15_dp", "problem16", "problem17", "problem19", "problem20", "problem21", "problem23", "problem24", "problem25", "problem26", "problem27", "problem28", "problem29", "problem30", "problem31", "problem31_recursive", "problem32", "problem33", "problem34", "problem35", "problem36", "problem37", "problem38", "problem39", "problem40", "problem41", "problem43", "problem44", "problem45", "problem46", "problem47", "problem48", "problem49", "problem50", "problem51", "problem52", "problem53", "problem55", "problem57", "problem60", "problem62", "problem64", "problem65", "problem68", "problem69", "problem70", "problem72", "problem73", "problem75", "problem76", "problem77", "problem78", "problem79", "problem80", "problem85", "problem86", "problem87", "problem89", "problem95", "problem91", "problem92", "problem94", "problem97", "problem100", "problem101", "problem104", "problem109", "problem111", "problem112", "problem113", "problem114", "problem115", "problem116", "problem117", "problem119", "problem120", "problem121", "problem122", "problem123", "problem125", "problem129", "problem131", "problem135", "problem136", "problem137", "problem138", "problem142", "problem145", "problem164", "problem173", "problem180", "problem187", "problem190", "problem191", "problem203", "problem205", "problem206", "problem234", "problem301", "problem401", "problem493", "problem551", "problem686", "endian_converter", "euler_totient", "byte_encoding_utils", "liouville_lambda", "liouville", "twos_complement_of_binary", "gauss_easter", "leap_year", "check_even", "is_odd", "binary_length", "count_set_bits", "count_leading_zeros", "clear_leftmost_set_bit", "clear_lowest_set_bit", "sum_of_odd_numbers", "sum_multiples_inclusion_exclusion", "carmichael_number", "evil_number", "keith_number", "kynea_numbers", "padovan_sequence", "pell_number", "perrin_number", "smith_number", "sphenic_number", "all_ones_sequence", "all_twos_sequence", "all_threes_sequence", "cubes_sequence")
ALGORITHMS += ("binary_palindrome_check",)
ALGORITHMS += ("mersenne_primes",)
ALGORITHMS += ("trial_division_factorizer",)
ALGORITHMS += ("magic_square",)
I64_MIN, I64_MAX = -(2**63), 2**63 - 1

PROBLEM79_KEYLOG = (319, 680, 180, 690, 129, 620, 762, 689, 762, 318,
                    368, 710, 720, 710, 629, 168, 160, 689, 716, 731,
                    736, 729, 316, 729, 729, 710, 769, 290, 719, 680,
                    318, 389, 162, 289, 162, 718, 729, 319, 790, 680,
                    890, 362, 319, 760, 316, 729, 380, 319, 728, 716)

PROBLEM8_DIGITS = (
    "7316717653133062491922511967442657474235534919493496983520312774506326239578318016984801869478851843"
    "8586156078911294949545950173795833195285320880551112540698747158523863050715693290963295227443043557"
    "6689664895044524452316173185640309871112172238311362229893423380308135336276614282806444486645238749"
    "3035890729629049156044077239071381051585930796086670172427121883998797908792274921901699720888093776"
    "6572733300105336788122023542180975125454059475224352584907711670556013604839586446706324415722155397"
    "5369781797784617406495514929086256932197846862248283972241375657056057490261407972968652414535100474"
    "8216637048440319989000889524345065854122758866688116427171479924442928230863465674813919123162824586"
    "1786645835912456652947654568284891288314260769004224219022671055626321111109370544217506941658960408"
    "0719840385096245544436298123098787992724428490918884580156166097919133875499200524063689912560717606"
    "0588611646710940507754100225698315520005593572972571636269561882670428252483600823257530420752963450"
)


def fibonacci_pair(n: int) -> tuple[int, int]:
    """Fast doubling oracle; independent of the ports' linear recurrence."""
    if n == 0:
        return 0, 1
    a, b = fibonacci_pair(n // 2)
    even, odd = a * (2 * b - a), a * a + b * b
    return (odd, even + odd) if n % 2 else (even, odd)


@lru_cache(maxsize=1)
def primes_for_problem7() -> tuple[int, ...]:
    """Sieve a bounded prime prefix for the Project Euler nth-prime oracle."""
    limit = 200_000
    prime = bytearray(b"\x01") * (limit + 1)
    prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(limit) + 1):
        if prime[value]:
            prime[value * value:limit + 1:value] = b"\x00" * (((limit - value * value) // value) + 1)
    return tuple(value for value, is_prime in enumerate(prime) if is_prime)


@lru_cache(maxsize=1)
def prime_sum_prefix_for_problem10() -> tuple[int, ...]:
    """Build inclusive prime-sum prefixes with a full-range byte sieve."""
    limit = 2_000_000
    prime = bytearray(b"\x01") * (limit + 1)
    prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(limit) + 1):
        if prime[value]:
            prime[value * value:limit + 1:value] = b"\x00" * (((limit - value * value) // value) + 1)
    prefix = [0] * (limit + 1)
    total = 0
    for value, is_prime in enumerate(prime):
        if is_prime:
            total += value
        prefix[value] = total
    return tuple(prefix)


@lru_cache(maxsize=128)
def problem10_ruby_prefix_oracle(max_total: int) -> int:
    """Use the independent prime-sum prefix to locate Ruby's strict cutoff."""
    if not 0 <= max_total <= 2_000_000:
        return -1
    prime_prefix = prime_sum_prefix_for_problem10()
    first_prefix_at_or_above = bisect_left(prime_prefix, max_total - 1)
    return 1 + prime_prefix[max(0, first_prefix_at_or_above - 1)]


@lru_cache(maxsize=1)
def collatz_best_prefix_for_problem14() -> tuple[int, ...]:
    """Memoize Collatz lengths iteratively, then retain the best start at each limit."""
    limit = 1_000_000
    lengths = [0] * (limit + 1)
    lengths[1] = 1
    external_lengths = {1: 1}
    best_by_limit = [0] * (limit + 1)
    best_by_limit[1] = 1
    best_start, best_length = 1, 1

    for start in range(2, limit + 1):
        current = start
        trail = []
        while True:
            if current <= limit and lengths[current] != 0:
                chain_length = lengths[current]
                break
            if current > limit and current in external_lengths:
                chain_length = external_lengths[current]
                break
            trail.append(current)
            current = current // 2 if current % 2 == 0 else 3 * current + 1
        for value in reversed(trail):
            chain_length += 1
            if value <= limit:
                lengths[value] = chain_length
            else:
                external_lengths[value] = chain_length
        if lengths[start] > best_length:
            best_start, best_length = start, lengths[start]
        best_by_limit[start] = best_start
    return tuple(best_by_limit)


@lru_cache(maxsize=1)
def triangular_first_at_divisor_threshold() -> tuple[int, ...]:
    """Map divisor thresholds to first triangular values via full-value factorization."""
    first = [0] * 501
    first[0] = 1
    unresolved = 500
    for index in range(1, 12_376):
        value = index * (index + 1) // 2
        remaining, divisor_count, factor = value, 1, 2
        while factor <= remaining // factor:
            exponent = 0
            while remaining % factor == 0:
                remaining //= factor
                exponent += 1
            if exponent:
                divisor_count *= exponent + 1
            factor = 3 if factor == 2 else factor + 2
        if remaining > 1:
            divisor_count *= 2
        for threshold in range(1, min(divisor_count, 500) + 1):
            if first[threshold] == 0:
                first[threshold] = value
                unresolved -= 1
        if unresolved == 0:
            break
    return tuple(first)


@lru_cache(maxsize=None)
def proper_divisor_sum_problem21(value: int) -> int:
    """Compute d(n) by the multiplicative sigma formula, not divisor-pair scans."""
    if value <= 1:
        return 0
    remaining, sigma, factor = value, 1, 2
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
    return sigma - value


@lru_cache(maxsize=None)
def is_prime_miller_rabin_problem27(value: int) -> bool:
    """Deterministic 64-bit Miller-Rabin oracle, unlike port trial division."""
    if value < 2:
        return False
    for small_prime in (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37):
        if value % small_prime == 0:
            return value == small_prime
    if value >= 2**64:
        for factor in range(41, math.isqrt(value) + 1, 2):
            if value % factor == 0:
                return False
        return True
    odd_part, power_of_two = value - 1, 0
    while odd_part % 2 == 0:
        odd_part //= 2
        power_of_two += 1
    for base in (2, 325, 9375, 28178, 450775, 9780504, 1795265022):
        if base % value == 0:
            continue
        witness = pow(base, odd_part, value)
        if witness in (1, value - 1):
            continue
        for _ in range(power_of_two - 1):
            witness = witness * witness % value
            if witness == value - 1:
                break
        else:
            return False
    return True


@lru_cache(maxsize=16)
def problem27_best_product(limit: int) -> int:
    """Follow source coefficient order while using Miller-Rabin for primality."""
    best_length, best_product = 0, 0
    for a in range(1 - limit, limit):
        for b in range(2, limit):
            if not is_prime_miller_rabin_problem27(b):
                continue
            length, n = 0, 0
            while is_prime_miller_rabin_problem27(n * n + a * n + b):
                length += 1
                n += 1
            if length > best_length:
                best_length, best_product = length, a * b
    return best_product


@lru_cache(maxsize=16)
def problem23_non_abundant_sum(limit: int) -> int:
    """Use factorization for abundance, distinct from ports' divisor-sum sieve."""
    abundant = [value for value in range(1, limit + 1)
                if proper_divisor_sum_problem21(value) > value]
    representable = bytearray(limit + 1)
    for index, left in enumerate(abundant):
        for right in abundant[index:]:
            total = left + right
            if total > limit:
                break
            representable[total] = 1
    return sum(value for value in range(1, limit + 1) if not representable[value])


@lru_cache(maxsize=1)
def problem25_first_indices_by_digit_count() -> tuple[int, ...]:
    """Build Fibonacci digit thresholds with Python big integers."""
    first_indices = []
    previous, current, index = 1, 1, 2
    previous_digits = 1
    while previous_digits < 1000:
        previous, current = current, previous + current
        index += 1
        digits = len(str(current))
        if digits > previous_digits:
            first_indices.append(index)
            previous_digits = digits
    return tuple(first_indices)


PROBLEM11_SOL1_GRID = (
    (8, 2, 22, 97, 38, 15, 0, 40, 0, 75, 4, 5, 7, 78, 52, 12, 50, 77, 91, 8),
    (49, 49, 99, 40, 17, 81, 18, 57, 60, 87, 17, 40, 98, 43, 69, 48, 4, 56, 62, 0),
    (81, 49, 31, 73, 55, 79, 14, 29, 93, 71, 40, 67, 53, 88, 30, 3, 49, 13, 36, 65),
    (52, 70, 95, 23, 4, 60, 11, 42, 69, 24, 68, 56, 1, 32, 56, 71, 37, 2, 36, 91),
    (22, 31, 16, 71, 51, 67, 63, 89, 41, 92, 36, 54, 22, 40, 40, 28, 66, 33, 13, 80),
    (24, 47, 32, 60, 99, 3, 45, 2, 44, 75, 33, 53, 78, 36, 84, 20, 35, 17, 12, 50),
    (32, 98, 81, 28, 64, 23, 67, 10, 26, 38, 40, 67, 59, 54, 70, 66, 18, 38, 64, 70),
    (67, 26, 20, 68, 2, 62, 12, 20, 95, 63, 94, 39, 63, 8, 40, 91, 66, 49, 94, 21),
    (24, 55, 58, 5, 66, 73, 99, 26, 97, 17, 78, 78, 96, 83, 14, 88, 34, 89, 63, 72),
    (21, 36, 23, 9, 75, 0, 76, 44, 20, 45, 35, 14, 0, 61, 33, 97, 34, 31, 33, 95),
    (78, 17, 53, 28, 22, 75, 31, 67, 15, 94, 3, 80, 4, 62, 16, 14, 9, 53, 56, 92),
    (16, 39, 5, 42, 96, 35, 31, 47, 55, 58, 88, 24, 0, 17, 54, 24, 36, 29, 85, 57),
    (86, 56, 0, 48, 35, 71, 89, 7, 5, 44, 44, 37, 44, 60, 21, 58, 51, 54, 17, 58),
    (19, 80, 81, 68, 5, 94, 47, 69, 28, 73, 92, 13, 86, 52, 17, 77, 4, 89, 55, 40),
    (4, 52, 8, 83, 97, 35, 99, 16, 7, 97, 57, 32, 16, 26, 26, 79, 33, 27, 98, 66),
    (88, 36, 68, 87, 57, 62, 20, 72, 3, 46, 33, 67, 46, 55, 12, 32, 63, 93, 53, 69),
    (4, 42, 16, 73, 38, 25, 39, 11, 24, 94, 72, 18, 8, 46, 29, 32, 40, 62, 76, 36),
    (20, 69, 36, 41, 72, 30, 23, 88, 34, 62, 99, 69, 82, 67, 59, 85, 74, 4, 36, 16),
    (20, 73, 35, 29, 78, 31, 90, 1, 74, 31, 49, 71, 48, 86, 81, 16, 23, 57, 5, 54),
    (1, 70, 54, 71, 83, 51, 54, 69, 16, 92, 33, 48, 61, 43, 52, 1, 89, 19, 67, 48),
)

@lru_cache(maxsize=1)
def problem11_sol1_oracle(ignored: int) -> int:
    """Enumerate bounded four-cell segments of the fixed grid."""
    if ignored != 0:
        return -1
    products = []
    for row in range(20):
        for column in range(20):
            if column + 3 < 20:
                products.append(PROBLEM11_SOL1_GRID[row][column] * PROBLEM11_SOL1_GRID[row][column + 1]
                                * PROBLEM11_SOL1_GRID[row][column + 2] * PROBLEM11_SOL1_GRID[row][column + 3])
            if row + 3 < 20:
                products.append(PROBLEM11_SOL1_GRID[row][column] * PROBLEM11_SOL1_GRID[row + 1][column]
                                * PROBLEM11_SOL1_GRID[row + 2][column] * PROBLEM11_SOL1_GRID[row + 3][column])
            if row + 3 < 20 and column + 3 < 20:
                products.append(PROBLEM11_SOL1_GRID[row][column] * PROBLEM11_SOL1_GRID[row + 1][column + 1]
                                * PROBLEM11_SOL1_GRID[row + 2][column + 2] * PROBLEM11_SOL1_GRID[row + 3][column + 3])
            if row + 3 < 20 and column >= 3:
                products.append(PROBLEM11_SOL1_GRID[row][column] * PROBLEM11_SOL1_GRID[row + 1][column - 1]
                                * PROBLEM11_SOL1_GRID[row + 2][column - 2] * PROBLEM11_SOL1_GRID[row + 3][column - 3])
    return max(products, default=0)


@lru_cache(maxsize=1)
def problem30_fixed_sum() -> int:
    """Enumerate six-digit multisets, then verify their candidate values."""
    candidates = set()
    for digits in combinations_with_replacement(range(10), 6):
        value = sum(digit**5 for digit in digits)
        if 1_000 <= value < 1_000_000:
            if sum(int(character)**5 for character in str(value)) == value:
                candidates.add(value)
    return sum(candidates)


@lru_cache(maxsize=1)
def problem32_distinct_product_sum() -> int:
    """Search multiplication identities directly, independent of permutations."""
    products = set()
    target = "123456789"
    for left_min, left_max, right_min, right_max in ((10, 99, 100, 999), (1, 9, 1000, 9999)):
        for left in range(left_min, left_max + 1):
            for right in range(right_min, right_max + 1):
                product = left * right
                if not 1000 <= product <= 9999:
                    continue
                digits = str(left) + str(right) + str(product)
                if len(digits) == 9 and "0" not in digits and "".join(sorted(digits)) == target:
                    products.add(product)
    return sum(products)


@lru_cache(maxsize=None)
def problem31_recursive_ways(remaining: int, coin_index: int = 0) -> int:
    """Count unordered coin combinations by memoized denomination recursion."""
    coins = (1, 2, 5, 10, 20, 50, 100, 200)
    if coin_index == len(coins):
        return int(remaining == 0)
    coin = coins[coin_index]
    return sum(problem31_recursive_ways(remaining - count * coin, coin_index + 1)
               for count in range(remaining // coin + 1))


@lru_cache(maxsize=1)
def problem34_fixed_sum() -> int:
    """Enumerate digit multisets and verify candidate digit-factorial sums."""
    factorials = tuple(math.factorial(digit) for digit in range(10))
    candidates = set()
    for digits in combinations_with_replacement(range(10), 7):
        value = sum(factorials[digit] for digit in digits)
        if 3 <= value <= 7 * math.factorial(9):
            if value == sum(factorials[int(digit)] for digit in str(value)):
                candidates.add(value)
    return sum(candidates)


@lru_cache(maxsize=1)
def problem35_circular_prime_count() -> int:
    """Count circular primes through one million via Miller-Rabin rotations."""
    count = 1  # the pinned search pre-counts 2
    for candidate in range(3, 1_000_001, 2):
        digits = str(candidate)
        if any((ord(character) - ord("0")) % 2 == 0 for character in digits):
            continue
        rotation = digits
        for _ in digits:
            if not is_prime_miller_rabin_problem27(int(rotation)):
                break
            rotation = rotation[1:] + rotation[0]
        else:
            count += 1
    return count


@lru_cache(maxsize=1)
def problem37_truncatable_prime_sum() -> int:
    """Scan the bounded candidates and use Miller-Rabin on each truncation."""
    total = 0
    for candidate in range(13, 1_000_001, 2):
        if not is_prime_miller_rabin_problem27(candidate):
            continue
        digits = str(candidate)
        if all(is_prime_miller_rabin_problem27(int(digits[offset:]))
               and is_prime_miller_rabin_problem27(int(digits[:len(digits) - offset]))
               for offset in range(1, len(digits))):
            total += candidate
    return total


@lru_cache(maxsize=1)
def problem36_double_base_palindromes() -> tuple[int, ...]:
    """Generate decimal palindromes from their leading half and filter binary."""
    values = []
    for digits_count in range(1, 7):
        half_length = (digits_count + 1) // 2
        for leading in range(10 ** (half_length - 1), 10**half_length):
            prefix = str(leading)
            suffix = prefix[:-1] if digits_count % 2 else prefix
            value = int(prefix + suffix[::-1])
            binary = format(value, "b")
            if binary == binary[::-1]:
                values.append(value)
    return tuple(sorted(values))


@lru_cache(maxsize=1)
def problem39_right_triangle_tables() -> tuple[tuple[int, ...], dict[int, tuple[int, int]]]:
    """Count scaled Euclid triples and record first nested-loop leg order."""
    counts = [0] * 1001
    first_legs: dict[int, tuple[int, int]] = {}
    for m in range(2, 32):
        for k in range(1, m):
            if math.gcd(m, k) != 1 or (m - k) % 2 == 0:
                continue
            perimeter = 2 * m * (m + k)
            if perimeter > 1000:
                continue
            left_leg, right_leg = m * m - k * k, 2 * m * k
            for scale in range(1, 1000 // perimeter + 1):
                total = scale * perimeter
                counts[total] += 1
                legs = tuple(sorted((scale * left_leg, scale * right_leg)))
                if total not in first_legs or legs < first_legs[total]:
                    first_legs[total] = legs
    return tuple(counts), first_legs


@lru_cache(maxsize=1000)
def problem39_best_perimeter(limit: int) -> int:
    counts, first_legs = problem39_right_triangle_tables()
    order = sorted((perimeter for perimeter in first_legs if perimeter <= limit),
                   key=lambda perimeter: first_legs[perimeter])
    best_perimeter, best_count = 0, 0
    for perimeter in order:
        if counts[perimeter] > best_count:
            best_perimeter, best_count = perimeter, counts[perimeter]
    return best_perimeter


@lru_cache(maxsize=1)
def problem40_champernowne_digit_product() -> int:
    """Locate fixed 1-indexed digits by decimal-width blocks."""
    product = 1
    for original_position in (1, 10, 100, 1_000, 10_000, 100_000, 1_000_000):
        position, width, block = original_position, 1, 9
        while position > width * block:
            position -= width * block
            width += 1
            block *= 10
        number = 10 ** (width - 1) + (position - 1) // width
        product *= int(str(number)[(position - 1) % width])
    return product


@lru_cache(maxsize=4)
def problem47_first_consecutive_base(distinct_count: int) -> int:
    """Sieve omega(n) and find the first run with the requested count."""
    limit = 1024
    while True:
        factor_counts = bytearray(limit + 1)
        for prime in range(2, limit + 1):
            if factor_counts[prime] == 0:
                for multiple in range(prime, limit + 1, prime):
                    factor_counts[multiple] += 1
        run = 0
        for value in range(2, limit + 1):
            if factor_counts[value] == distinct_count:
                run += 1
                if run == distinct_count:
                    return value - distinct_count + 1
            else:
                run = 0
        limit *= 2


@lru_cache(maxsize=9)
def problem41_largest_pandigital_prime(digit_count: int) -> int:
    if sum(range(1, digit_count + 1)) % 3 == 0:
        return 0
    for digits in permutations(range(digit_count, 0, -1)):
        value = 0
        for digit in digits:
            value = value * 10 + digit
        if is_prime_miller_rabin_problem27(value):
            return value
    return 0


@lru_cache(maxsize=16)
def problem44_first_pentagonal_difference(limit: int) -> int:
    values = [index * (3 * index - 1) // 2 for index in range(1, limit)]
    if not values:
        return -1
    maximum_sum = 2 * values[-1]
    pentagonal = set()
    index = 1
    while True:
        value = index * (3 * index - 1) // 2
        if value > maximum_sum:
            break
        pentagonal.add(value)
        index += 1
    for lower in range(len(values)):
        for upper in range(lower + 1, len(values)):
            difference = values[upper] - values[lower]
            total = values[upper] + values[lower]
            if difference in pentagonal and total in pentagonal:
                return difference
    return -1


@lru_cache(maxsize=1)
def problem46_goldbach_other_counterexample() -> int:
    """Use an independent sieve to find the first odd-composite counterexample."""
    limit = 100_000
    prime = bytearray(b"\x01") * limit
    prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(limit - 1) + 1):
        if prime[value]:
            prime[value * value:limit:value] = b"\x00" * (((limit - 1 - value * value) // value) + 1)
    for value in range(9, limit, 2):
        if prime[value]:
            continue
        if not any(value - p >= 2 and (value - p) % 2 == 0
                   and math.isqrt((value - p) // 2) ** 2 == (value - p) // 2
                   for p in range(2, value)):
            return value
    return -1


@lru_cache(maxsize=32)
def problem72_oracle(limit: int) -> int:
    """Linear totient sieve, independent of the ports' divisor-update sieve."""
    if not 0 <= limit <= 1_000_000:
        return -1
    if limit < 2:
        return 0
    phi = [0] * (limit + 1)
    composite = bytearray(limit + 1)
    primes: list[int] = []
    phi[1] = 1
    for value in range(2, limit + 1):
        if not composite[value]:
            primes.append(value)
            phi[value] = value - 1
        for prime in primes:
            product_value = value * prime
            if product_value > limit:
                break
            composite[product_value] = 1
            if value % prime == 0:
                phi[product_value] = phi[value] * prime
                break
            phi[product_value] = phi[value] * (prime - 1)
    return sum(phi[2:])


@lru_cache(maxsize=4)
def problem70_oracle(limit: int) -> int:
    """Classic full sieve oracle, independent of the ports' segmented sieve."""
    if not 0 <= limit <= 10_000_000:
        return -1
    phi = array("I", range(limit + 1))
    for prime in range(2, limit + 1):
        if phi[prime] == prime:
            for multiple in range(prime, limit + 1, prime):
                phi[multiple] -= phi[multiple] // prime
    best, best_phi = 0, 1
    for number in range(2, limit + 1):
        value = phi[number]
        improves = best == 0 or number * best_phi < best * value
        if improves and sorted(str(number)) == sorted(str(value)):
            best, best_phi = number, value
    return best or 1


@lru_cache(maxsize=256)
def problem76_oracle(total: int) -> int:
    """Independent unbounded-sum partition dynamic program."""
    if not 1 <= total <= 200:
        return -1
    partitions = [0] * (total + 1)
    partitions[0] = 1
    for part in range(1, total):
        for value in range(part, total + 1):
            partitions[value] += partitions[value - part]
    return partitions[total]


@lru_cache(maxsize=128)
def problem75_oracle(limit: int) -> int:
    """Count singular perimeters with Euclid's primitive triple parametrization."""
    if limit > 1_500_000:
        return -1
    counts = bytearray(max(0, limit) + 1)
    m = 2
    while 2 * m * (m + 1) <= limit:
        for n in range((m % 2) + 1, m, 2):
            if math.gcd(m, n) != 1:
                continue
            perimeter = 2 * m * (m + n)
            for multiple in range(perimeter, limit + 1, perimeter):
                if counts[multiple] < 2:
                    counts[multiple] += 1
        m += 1
    return counts.count(1)


@lru_cache(maxsize=128)
def problem78_oracle(modulus: int) -> int:
    """Use the pentagonal recurrence, summing signed offsets before reduction."""
    if not 1 <= modulus <= 1_000_000:
        return -1
    residues = [1 % modulus]
    for n in range(1, 55_375):
        signed_terms = 0
        index = 1
        while True:
            lower = index * (3 * index - 1) // 2
            if lower > n:
                break
            sign = 1 if index % 2 else -1
            signed_terms += sign * residues[n - lower]
            upper = index * (3 * index + 1) // 2
            if upper <= n:
                signed_terms += sign * residues[n - upper]
            index += 1
        residue = signed_terms % modulus
        if residue == 0:
            return n
        residues.append(residue)
    return -1


def problem79_oracle(placeholder: int) -> int:
    """Derive the canonical keylog passcode from its digit precedence DAG."""
    if placeholder != 0:
        return -1
    digits = {digit for login in PROBLEM79_KEYLOG
              for digit in (login // 100, (login // 10) % 10, login % 10)}
    edges = {digit: set() for digit in digits}
    indegree = {digit: 0 for digit in digits}
    for login in PROBLEM79_KEYLOG:
        first, second, third = login // 100, (login // 10) % 10, login % 10
        for left, right in ((first, second), (second, third)):
            if right not in edges[left]:
                edges[left].add(right)
                indegree[right] += 1
    remaining = set(digits)
    passcode = 0
    while remaining:
        available = [digit for digit in remaining if indegree[digit] == 0]
        if not available:
            return -1
        digit = min(available)
        remaining.remove(digit)
        passcode = passcode * 10 + digit
        for successor in edges[digit]:
            indegree[successor] -= 1
    return passcode


@lru_cache(maxsize=32)
def problem86_oracle(threshold: int) -> int:
    """Enumerate integer hypotenuse candidates instead of source's path sums."""
    if threshold > 1_000_000:
        return -1
    if threshold < 0:
        return 0
    cumulative = 0
    side = 0
    while cumulative <= threshold:
        side += 1
        side_squared = side * side
        for hypotenuse in range(math.isqrt(side_squared + 4), math.isqrt(5 * side_squared) + 1):
            combined_squared = hypotenuse * hypotenuse - side_squared
            combined = math.isqrt(combined_squared)
            if combined < 2 or combined * combined != combined_squared or combined > 2 * side:
                continue
            low_side = max(1, combined - side)
            high_side = min(side, combined // 2)
            cumulative += max(0, high_side - low_side + 1)
    return side


@lru_cache(maxsize=128)
def problem85_oracle(target: int) -> int:
    """Exhaustively find neighboring triangular counts for each bounded a."""
    if not 0 <= target <= 2_000_000_000:
        return -1
    bound = math.ceil(math.sqrt(2 * target) * 1.1)
    best_product, area = 0, 0
    for a in range(1, bound):
        triangle_a = a * (a + 1) // 2
        low, high = 0, max(1, target // triangle_a + 1)
        while low < high:
            middle = (low + high + 1) // 2
            if triangle_a * middle * (middle + 1) // 2 <= target:
                low = middle
            else:
                high = middle - 1
        for b in (low, low + 1):
            product = triangle_a * b * (b + 1) // 2
            if abs(target - product) < abs(target - best_product):
                best_product, area = product, a * b
    return area


@lru_cache(maxsize=64)
def problem91_oracle(limit: int) -> int:
    """Count right angles by primitive perpendicular directions at each point."""
    if not 0 <= limit <= 50:
        return -1
    count = limit * limit  # Right angle at the origin: one axis point per leg.
    for x in range(limit + 1):
        for y in range(limit + 1):
            if x == 0 and y == 0:
                continue
            divisor = math.gcd(x, y)
            dx, dy = y // divisor, x // divisor
            for sign in (-1, 1):
                step_x, step_y = sign * dx, -sign * dy
                max_steps = limit + 1
                if step_x > 0:
                    max_steps = min(max_steps, (limit - x) // step_x)
                elif step_x < 0:
                    max_steps = min(max_steps, x // -step_x)
                if step_y > 0:
                    max_steps = min(max_steps, (limit - y) // step_y)
                elif step_y < 0:
                    max_steps = min(max_steps, y // -step_y)
                count += max(0, max_steps)
    return count


def problem89_oracle(placeholder: int) -> int:
    if placeholder != 0:
        return -1
    numerals = (ROOT / "benchmarks/p/problem89/roman.txt").read_text(encoding="ascii").splitlines()
    values = {"I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000}
    place_lengths = ((0, 1, 2, 3, 2, 1, 2, 3, 4, 2),
                     (0, 1, 2, 3, 2, 1, 2, 3, 4, 2),
                     (0, 1, 2, 3, 2, 1, 2, 3, 4, 2))
    saved = 0
    for numeral in numerals:
        total = 0
        for index, symbol in enumerate(numeral):
            amount = values[symbol]
            total += -amount if index + 1 < len(numeral) and amount < values[numeral[index + 1]] else amount
        minimal_length = total // 1000
        hundreds, tens, ones = (total // 100) % 10, (total // 10) % 10, total % 10
        minimal_length += place_lengths[0][hundreds] + place_lengths[1][tens] + place_lengths[2][ones]
        saved += len(numeral) - minimal_length
    return saved


@lru_cache(maxsize=128)
def problem92_oracle(limit: int) -> int:
    """Count square-digit sums with suffix convolution, not prefix digit-DP."""
    if not 0 <= limit <= 10_000_000:
        return -1
    digits = list(map(int, str(limit)))
    suffix = [{0: 1}]
    for _ in range(len(digits)):
        next_counts: dict[int, int] = {}
        for subtotal, ways in suffix[-1].items():
            for digit in range(10):
                new_sum = subtotal + digit * digit
                next_counts[new_sum] = next_counts.get(new_sum, 0) + ways
        suffix.append(next_counts)

    sum_counts: dict[int, int] = {}
    prefix_sum = 0
    for index, bound_digit in enumerate(digits):
        remaining = len(digits) - index - 1
        for digit in range(bound_digit):
            base_sum = prefix_sum + digit * digit
            for suffix_sum, ways in suffix[remaining].items():
                total = base_sum + suffix_sum
                sum_counts[total] = sum_counts.get(total, 0) + ways
        prefix_sum += bound_digit * bound_digit

    def reaches_89(value: int) -> bool:
        if value == 0:
            return False
        while value not in (1, 89):
            value = sum((ord(character) - 48) ** 2 for character in str(value))
        return value == 89
    return sum(ways for digit_sum, ways in sum_counts.items() if reaches_89(digit_sum))


@lru_cache(maxsize=128)
def problem94_oracle(limit: int) -> int:
    """Sum the almost-equilateral perimeter sequence under the inclusive limit."""
    if not 0 <= limit <= 1_000_000_000:
        return -1
    previous, value, total, iteration, perimeter = 1, 2, 0, 0, 0
    while perimeter <= limit:
        total += perimeter
        previous, value = previous + 2 * value, previous + 3 * value
        perimeter = 2 * value + (2 if iteration % 2 == 0 else -2)
        iteration += 1
    return total


def problem97_oracle(digits: int) -> int:
    if not 0 <= digits <= 18:
        return -1
    modulus = 10 ** digits
    return (28433 * pow(2, 7_830_457, modulus) + 1) % modulus


@lru_cache(maxsize=128)
def problem100_oracle(min_total: int) -> int:
    """Generate Pell solutions of y² - 2x² = -1 until total exceeds the limit."""
    if not 0 <= min_total <= 1_000_000_000_000:
        return -1
    y, x = 1, 1
    while (y + 1) // 2 <= min_total:
        y, x = 3 * y + 4 * x, 2 * y + 3 * x
    return (x + 1) // 2


def problem101_oracle(order: int) -> int:
    if order > 10:
        return -1
    def sequence_term(position: int) -> int:
        return sum((-1) ** power * position ** power for power in range(11))
    total = 0
    for interpolation_order in range(1, max(0, order) + 1):
        x = interpolation_order + 1
        prediction = Fraction(0)
        for point in range(1, interpolation_order + 1):
            value = Fraction(sequence_term(point))
            for other in range(1, interpolation_order + 1):
                if point != other:
                    value *= Fraction(x - other, point - other)
            prediction += value
        total += int(prediction)
    return total


@lru_cache(maxsize=128)
def problem112_oracle(percent: int) -> int:
    if not 1 <= percent <= 99:
        return -1
    bouncy_count = 0
    for number in range(1, 2_000_001):
        digits = str(number)
        rising = falling = True
        for left, right in zip(digits, digits[1:]):
            rising &= left <= right
            falling &= left >= right
        bouncy_count += not (rising or falling)
        if bouncy_count * 100 >= percent * number:
            return number
    return -1


def problem113_oracle(max_digits: int) -> int:
    if max_digits > 100:
        return -1
    return sum(math.comb(8 + digits, digits) + math.comb(9 + digits, digits) - 10
               for digits in range(1, max(0, max_digits) + 1))


@lru_cache(maxsize=128)
def problem115_oracle(min_block_length: int) -> int:
    if not 1 <= min_block_length <= 100:
        return -1
    # Standard suffix decomposition: all-black extension plus a rightmost red block.
    ways = [1] * min_block_length
    for row_length in range(min_block_length, 1024):
        total = ways[row_length - 1]
        for block_length in range(min_block_length, row_length + 1):
            prefix_length = row_length - block_length - 1
            total += 1 if prefix_length < 0 else ways[prefix_length]
        ways.append(total)
        if total > 1_000_000:
            return row_length
    return -1


@lru_cache(maxsize=32)
def problem73_oracle(limit: int) -> int:
    """Count interval fractions by Möbius inversion over common divisors."""
    if not 0 <= limit <= 12_000:
        return -1
    mobius = [1] * (limit + 1)
    primes: list[int] = []
    composite = bytearray(limit + 1)
    for value in range(2, limit + 1):
        if not composite[value]:
            primes.append(value)
            mobius[value] = -1
        for prime in primes:
            product_value = value * prime
            if product_value > limit:
                break
            composite[product_value] = 1
            if value % prime == 0:
                mobius[product_value] = 0
                break
            mobius[product_value] = -mobius[value]

    # For each common divisor k, count all scaled pairs (a, d) in the
    # interval with d <= limit // k, then apply Möbius inversion.
    answer = 0
    for common_divisor in range(1, limit + 1):
        if mobius[common_divisor] == 0:
            continue
        scaled_limit = limit // common_divisor
        unrestricted = sum(max(0, (denominator - 1) // 2 - denominator // 3)
                           for denominator in range(1, scaled_limit + 1))
        answer += mobius[common_divisor] * unrestricted
    return answer


@lru_cache(maxsize=128)
def problem77_oracle(threshold: int) -> int:
    """Count unordered prime partitions recursively in nondecreasing order."""
    if not 0 <= threshold <= 100_000:
        return -1
    primes = tuple(value for value in range(2, 100)
                   if all(value % divisor for divisor in range(2, math.isqrt(value) + 1)))

    @lru_cache(maxsize=None)
    def count(remaining: int, first_prime: int) -> int:
        if remaining == 0:
            return 1
        return sum(count(remaining - prime, index)
                   for index, prime in enumerate(primes[first_prime:], first_prime)
                   if prime <= remaining)

    return next((value for value in range(1, 100)
                 if count(value, 0) > threshold), -1)


def problem80_oracle(placeholder: int) -> int:
    """Reproduce the pinned Context(prec=105) square-root digit extraction."""
    if placeholder != 0:
        return -1
    context = Context(prec=105)
    total = 0
    for value in range(2, 100):
        root = Decimal(value).sqrt(context)
        rendered = str(root)
        if len(rendered) > 1:
            total += int(rendered[0])
            total += sum(int(character) for character in rendered[2:101])
    return total


@lru_cache(maxsize=16)
def problem95_oracle(limit: int) -> int:
    """Build aliquot sums and follow each start with a local visited set."""
    if not 1 <= limit <= 1_000_000:
        return -1
    sums = [0] * (limit + 1)
    for divisor in range(1, limit // 2 + 1):
        for multiple in range(2 * divisor, limit + 1, divisor):
            sums[multiple] += divisor
    best_length = 0
    answer = 0
    for start in range(2, limit + 1):
        path = {start}
        element = sums[start]
        length = 1
        while element > 1 and element <= limit and element not in path:
            path.add(element)
            element = sums[element]
            length += 1
        if element == start and length > best_length:
            best_length = length
            answer = start
    return answer


@lru_cache(maxsize=16)
def problem87_oracle(limit: int) -> int:
    """Trial-division prime generation and a packed sum set."""
    if not 24 <= limit <= 50_000_000:
        return -1
    bound = max(2, math.isqrt(limit - 24))
    primes = tuple(value for value in range(2, bound + 1)
                   if all(value % divisor for divisor in range(2, math.isqrt(value) + 1)))
    seen = bytearray((limit + 7) // 8)
    for first in primes:
        square = first * first
        for second in primes:
            cube = second**3
            if square + cube >= limit - 16:
                break
            for third in primes:
                total = square + cube + third**4
                if total >= limit:
                    break
                seen[total >> 3] |= 1 << (total & 7)
    return sum(bin(bits).count("1") for bits in seen)


@lru_cache(maxsize=128)
def problem109_oracle(limit: int) -> int:
    """Enumerate ordered final doubles and unordered pairs of throw entries."""
    first_two = [*range(1, 21), 25, *range(2, 41, 2), 50,
                 *range(3, 61, 3), 0]
    final_doubles = [*range(2, 41, 2), 50]
    return sum(final_double + pair[0] + pair[1] < limit
               for final_double in final_doubles
               for pair in combinations_with_replacement(first_two, 2))


@lru_cache(maxsize=128)
def problem131_oracle(limit: int) -> int:
    """Use the closed-form candidate sequence and independent primality checks."""
    if not 0 <= limit <= 1_000_000:
        return -1

    def is_prime(candidate: int) -> bool:
        if candidate < 2:
            return False
        return all(candidate % divisor for divisor in range(2, math.isqrt(candidate) + 1))

    count = 0
    cube_index = 1
    while True:
        candidate = 3 * cube_index * (cube_index + 1) + 1
        if candidate >= limit:
            return count
        count += is_prime(candidate)
        cube_index += 1


@lru_cache(maxsize=128)
def problem125_oracle(limit: int) -> int:
    """Build sums from start/end square pairs, deduplicating palindromes."""
    if not 0 <= limit <= 100_000_000:
        return -1
    found = set()
    start = 1
    while start * start + (start + 1) * (start + 1) < limit:
        total = start * start + (start + 1) * (start + 1)
        end = start + 2
        while total < limit:
            digits = str(total)
            if digits == digits[::-1]:
                found.add(total)
            total += end * end
            end += 1
        start += 1
    return sum(found)


@lru_cache(maxsize=128)
def problem135_136_counts(limit: int) -> tuple[int, ...]:
    """Count ordered divisor representations via factorization, not source loops."""
    smallest = list(range(limit + 1))
    for prime in range(2, math.isqrt(limit) + 1):
        if smallest[prime] == prime:
            for multiple in range(prime * prime, limit + 1, prime):
                if smallest[multiple] == multiple:
                    smallest[multiple] = prime
    counts = [0] * (limit + 1)
    for number in range(1, limit + 1):
        remaining = number
        factors = []
        while remaining > 1:
            prime = smallest[remaining]
            exponent = 0
            while remaining % prime == 0:
                remaining //= prime
                exponent += 1
            factors.append((prime, exponent))
        divisors = [1]
        for prime, exponent in factors:
            expanded = []
            power = 1
            for _ in range(exponent + 1):
                expanded.extend(divisor * power for divisor in divisors)
                power *= prime
            divisors = expanded
        for first_term in divisors:
            quotient_sum = first_term + number // first_term
            if quotient_sum % 4 == 0:
                d = quotient_sum // 4
                if first_term > d and first_term < 4 * d and counts[number] < 11:
                    counts[number] += 1
    return tuple(counts)


@lru_cache(maxsize=128)
def problem145_oracle(max_power: int) -> int:
    """Count reversible digit strings with a separate list-based carry walk."""
    if max_power > 9:
        return -1
    if max_power <= 0:
        return 0

    def length_count(length: int) -> int:
        digits = [0] * length

        def visit(depth: int, carry: int) -> int:
            if depth == (length + 1) // 2:
                if digits[0] == 0 or digits[-1] == 0:
                    return 0
                high_carry = carry
                for column in range(length // 2 - 1, -1, -1):
                    high_carry += digits[column] + digits[length - column - 1]
                    if high_carry % 2 == 0:
                        return 0
                    high_carry //= 10
                if length % 2:
                    center = digits[length // 2]
                    high_carry += 2 * center
                    if high_carry % 2 == 0:
                        return 0
                    high_carry //= 10
                return 1
            result = 0
            left, right = depth, length - depth - 1
            low_digits = range(1, 10) if depth == 0 else range(10)
            high_digits = range(1, 10) if depth == 0 else range(10)
            for low_digit in low_digits:
                for high_digit in high_digits:
                    total = low_digit + high_digit + carry
                    if total % 2 != 1:
                        continue
                    digits[left], digits[right] = high_digit, low_digit
                    result += visit(depth + 1, total // 10)
            return result

        return visit(0, 0)

    return sum(length_count(length) for length in range(1, max_power + 1)
               if (length - 1) % 4 != 0)


@lru_cache(maxsize=128)
def problem173_oracle(limit: int) -> int:
    """Count parity-compatible inner square widths for every possible outer."""
    if not 0 <= limit <= 1_000_000:
        return -1
    total = 0
    for outer in range(3, limit // 4 + 2):
        minimum = max(1, math.isqrt(max(0, outer * outer - limit)))
        if minimum * minimum < outer * outer - limit:
            minimum += 1
        if (outer - minimum) % 2:
            minimum += 1
        final_width = outer - 2
        if minimum <= final_width:
            total += (final_width - minimum) // 2 + 1
    return total


@lru_cache(maxsize=128)
def problem164_oracle(digit_count: int) -> int:
    """Iterate allowed final-digit-pair states rather than source recursion."""
    if not 0 <= digit_count <= 26:
        return -1
    if digit_count == 0:
        return 1
    if digit_count == 1:
        return 9
    states = {(first, second): 1
              for first in range(1, 10)
              for second in range(10 - first)}
    for _ in range(2, digit_count):
        following = {}
        for (before_previous, previous), count in states.items():
            for digit in range(10 - before_previous - previous):
                key = (previous, digit)
                following[key] = following.get(key, 0) + count
        states = following
    return sum(states.values())


@lru_cache(maxsize=128)
def problem142_oracle(number_of_terms: int) -> int:
    """Search the bounded triples using integer square roots for validation."""
    if number_of_terms == 1:
        return 1
    if number_of_terms == 2:
        return 9
    if number_of_terms != 3:
        return -1

    def square_root_if_exact(value: int) -> int | None:
        if value < 0 or value > 2_500**2:
            return None
        root = math.isqrt(value)
        return root if root * root == value else None

    minimum = I64_MAX
    for a in range(1, 2_501):
        a_sq = a * a
        for b in range(1, 2_501):
            b_sq = b * b
            if square_root_if_exact(a_sq + b_sq) is None:
                continue
            for c in range(max(a, b) + 1, 2_501):
                c_sq = c * c
                if minimum != I64_MAX and (a_sq - b_sq + 3 * c_sq) // 2 > minimum:
                    break
                if (square_root_if_exact(c_sq - b_sq) is None
                        or square_root_if_exact(a_sq + c_sq) is None):
                    continue
                x2, y2, z2 = a_sq + b_sq + c_sq, a_sq - b_sq + c_sq, c_sq - a_sq - b_sq
                if z2 > 0 and x2 % 2 == y2 % 2 == z2 % 2 == 0:
                    minimum = min(minimum, (x2 + y2 + z2) // 2)
    return -1 if minimum == I64_MAX else minimum


@lru_cache(maxsize=128)
def problem138_oracle(count: int) -> int:
    """Use the scalar second-order Pell recurrence, not pair updates."""
    if count > 14:
        return -1
    if count <= 0:
        return 0
    previous, current = 1, 17
    total = 0
    for _ in range(count):
        total += current
        previous, current = current, 18 * current - previous
    return total


@lru_cache(maxsize=128)
def problem190_oracle(n: int) -> int:
    """Recompute source-observable binary64 products with Python's float semantics."""
    if not 0 <= n <= 15:
        return -1
    total = 0
    for m in range(2, n + 1):
        x1 = 2.0 / (m + 1)
        product = 1.0
        for i in range(1, m + 1):
            xi = i * x1
            product *= xi ** i
        total += int(product)
    return total


@lru_cache(maxsize=128)
def problem493_oracle(picks: int) -> int:
    """Round the exact hypergeometric expectation to nine places, ties-to-even."""
    if not 0 <= picks <= 70:
        return -1
    denominator = math.comb(70, 10)
    missing = math.comb(70 - picks, 10) if picks <= 60 else 0
    scaled_numerator = 7 * (denominator - missing) * 1_000_000_000
    scaled, remainder = divmod(scaled_numerator, denominator)
    doubled_remainder = 2 * remainder
    if doubled_remainder > denominator or (doubled_remainder == denominator and scaled % 2 != 0):
        scaled += 1
    return scaled


@lru_cache(maxsize=16)
def problem551_oracle(n: int) -> int:
    """Use the pinned little-endian digit-array jump cache as a separate model."""
    if not 1 <= n <= 1_000_000_000_000_000:
        return -1
    bases = [10**k for k in range(21)]
    memo: dict[int, dict[int, list[tuple[int, int, int]]]] = {}

    def add(digits: list[int], k: int, addend: int) -> None:
        for j in range(k, len(digits)):
            value = digits[j] + addend
            if value >= 10:
                quotient, digits[j] = divmod(value, 10)
                addend = addend // 10 + quotient
            else:
                digits[j] = value
                addend //= 10
            if addend == 0:
                break
        while addend > 0:
            addend, digit = divmod(addend, 10)
            digits.append(digit)

    def compute(digits: list[int], k: int, index: int, target: int) -> tuple[int, int]:
        if index >= target:
            return 0, 0
        if k > len(digits):
            digits.extend([0] * (k - len(digits)))
        start = index
        prefix_digit_sum = suffix_digit_sum = difference = 0
        for j, digit in enumerate(digits):
            if j >= k:
                prefix_digit_sum += digit
            else:
                suffix_digit_sum += digit
        while index < target:
            index += 1
            addend = suffix_digit_sum + prefix_digit_sum
            difference += addend
            suffix_digit_sum = 0
            for j in range(k):
                value = digits[j] + addend
                addend, digits[j] = divmod(value, 10)
                suffix_digit_sum += digits[j]
            if addend > 0:
                break
        if addend > 0:
            add(digits, k, addend)
        return difference, index - start

    def next_term(digits: list[int], k: int, index: int, target: int) -> tuple[int, int]:
        prefix_digit_sum = sum(digits[k:])
        suffix = sum(digits[j] * bases[j] for j in range(min(len(digits), k)))
        difference = terms = 0
        max_terms = target - index
        sub_memo = memo.get(prefix_digit_sum)
        if sub_memo is not None:
            jumps = sub_memo.get(suffix)
            if jumps is not None and jumps:
                best = None
                for jump in reversed(jumps):
                    if jump[2] <= k and jump[1] <= max_terms:
                        best = jump
                        break
                if best is not None:
                    difference, terms, _ = best
                    new_suffix = difference + suffix
                    for j in range(min(k, len(digits))):
                        new_suffix, digits[j] = divmod(new_suffix, 10)
                    if new_suffix > 0:
                        add(digits, k, new_suffix)
            else:
                sub_memo[suffix] = []
        else:
            sub_memo = {suffix: []}
            memo[prefix_digit_sum] = sub_memo
        if terms >= max_terms or suffix + difference >= bases[k]:
            return difference, terms
        if k > 2:
            while True:
                extra, jumped = next_term(digits, k - 1, index + terms, target)
                difference += extra
                terms += jumped
                if terms >= max_terms or suffix + difference >= bases[k]:
                    break
        else:
            extra, jumped = compute(digits, k, index + terms, target)
            difference += extra
            terms += jumped
        jumps = sub_memo[suffix]
        position = 0
        while position < len(jumps):
            if jumps[position][1] > terms:
                break
            position += 1
        jumps.insert(position, (difference, terms, k))
        return difference, terms

    digits = [1]
    index = 1
    jumped = 0
    while True:
        _, terms = next_term(digits, 20, index + jumped, n)
        jumped += terms
        if jumped == n - index:
            return sum(digit * 10**place for place, digit in enumerate(digits))


@lru_cache(maxsize=1)
def problem206_oracle(unused: int) -> int:
    """Search upward from the minimum possible root, unlike the pinned scan."""
    if unused != 0:
        return -1
    lower_square = 10_203_040_506_070_809
    upper_square = 19_293_949_596_979_899
    candidate = math.isqrt(lower_square)
    if candidate * candidate < lower_square:
        candidate += 1
    while candidate % 10 not in (3, 7):
        candidate += 1
    upper = math.isqrt(upper_square)
    while upper % 10 not in (3, 7):
        upper -= 1
    while candidate <= upper:
        value = candidate * candidate
        target = 9
        square_form = True
        while target >= 1:
            if value % 10 != target:
                square_form = False
                break
            value //= 100
            target -= 1
        if square_form and value == 0:
            return candidate * 10
        candidate += 4 if candidate % 10 == 3 else 6
    return -1


@lru_cache(maxsize=8)
def problem187_prime_pool(limit: int) -> tuple[int, ...]:
    """Sieve a bounded candidate pool for the P187 independent oracle."""
    if limit <= 2:
        return ()
    prime = bytearray(b"\x01") * limit
    prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(limit - 1) + 1):
        if prime[value]:
            start = value * value
            prime[start:limit:value] = b"\x00" * (((limit - 1 - start) // value) + 1)
    return tuple(value for value, is_prime in enumerate(prime) if is_prime)


@lru_cache(maxsize=128)
def problem187_oracle(max_number: int) -> int:
    """Count pairs via per-prime binary searches, independent of source two pointers."""
    if not 0 <= max_number <= 100_000_000:
        return -1
    primes = problem187_prime_pool(max_number // 2)
    return sum(max(0, bisect_right(primes, (max_number - 1) // prime) - index)
               for index, prime in enumerate(primes))


@lru_cache(maxsize=32)
def problem180_oracle(order: int) -> int:
    """Enumerate reduced rational pairs and test the four equations directly."""
    if not 1 <= order <= 35:
        return -1

    def rational_sqrt(value: Fraction) -> Fraction | None:
        numerator_root = math.isqrt(value.numerator)
        denominator_root = math.isqrt(value.denominator)
        if (numerator_root * numerator_root == value.numerator
                and denominator_root * denominator_root == value.denominator):
            return Fraction(numerator_root, denominator_root)
        return None

    rationals = {Fraction(numerator, denominator)
                 for denominator in range(2, order + 1)
                 for numerator in range(1, denominator)}
    unique_sums: set[Fraction] = set()
    for x in rationals:
        for y in rationals:
            candidates = [x + y, x * y / (x + y)]
            square_sum = x * x + y * y
            candidates.extend((rational_sqrt(square_sum),
                               rational_sqrt(x * x * y * y / square_sum)))
            for z in candidates:
                if z is not None and 0 < z < 1 and z.denominator <= order:
                    unique_sums.add(x + y + z)
    total = sum(unique_sums, Fraction(0))
    return total.numerator + total.denominator


@lru_cache(maxsize=1)
def problem203_primes() -> tuple[int, ...]:
    """Generate primes up to sqrt of the largest supported binomial coefficient."""
    limit = math.isqrt(math.comb(50, 25))
    prime = bytearray(b"\x01") * (limit + 1)
    prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(limit) + 1):
        if prime[value]:
            start = value * value
            prime[start:limit + 1:value] = b"\x00" * (((limit - start) // value) + 1)
    return tuple(value for value, is_prime in enumerate(prime) if is_prime)


@lru_cache(maxsize=8192)
def problem203_is_squarefree(value: int) -> bool:
    for prime in problem203_primes():
        if prime * prime > value:
            break
        if value % (prime * prime) == 0:
            return False
    return True


@lru_cache(maxsize=128)
def problem203_oracle(depth: int) -> int:
    """Use direct binomial coefficients and prime-square divisibility checks."""
    if depth > 51:
        return -1
    coefficients = {1}
    coefficients.update(math.comb(row, column)
                        for row in range(max(0, depth))
                        for column in range(row + 1))
    return sum(value for value in coefficients if problem203_is_squarefree(value))


@lru_cache(maxsize=1)
def problem205_oracle(placeholder: int) -> int:
    """Use convolution and integer ties-to-even rounding for the exact dice counts."""
    if placeholder != 0:
        return -1

    def distribution(sides: int, dice: int) -> list[int]:
        counts = [1]
        for _ in range(dice):
            following = [0] * (len(counts) + sides)
            for subtotal, count in enumerate(counts):
                if count:
                    for face in range(1, sides + 1):
                        following[subtotal + face] += count
            counts = following
        return counts

    peter = distribution(4, 9)
    colin = distribution(6, 6)
    colin_below = 0
    wins = 0
    for total, peter_count in enumerate(peter):
        wins += peter_count * colin_below
        if total < len(colin):
            colin_below += colin[total]
    denominator = 4**9 * 6**6
    quotient, remainder = divmod(wins * 10_000_000, denominator)
    if 2 * remainder > denominator or (2 * remainder == denominator and quotient % 2):
        quotient += 1
    return quotient


@lru_cache(maxsize=8)
def problem234_prime_list(limit: int) -> tuple[int, ...]:
    """Sieve primes for the direct semidivisible-number oracle."""
    if limit <= 2:
        return ()
    prime = bytearray(b"\x01") * limit
    prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(limit - 1) + 1):
        if prime[value]:
            start = value * value
            prime[start:limit:value] = b"\x00" * (((limit - 1 - start) // value) + 1)
    return tuple(value for value, is_prime in enumerate(prime) if is_prime)


@lru_cache(maxsize=128)
def problem234_oracle(limit: int) -> int:
    """Check lower/upper-prime multiples directly, excluding common multiples."""
    if not 0 <= limit <= 999_966_663_333:
        return -1
    primes = problem234_prime_list(math.isqrt(limit) + 100)
    total = 0
    for lower_prime, upper_prime in zip(primes, primes[1:]):
        lower_square, upper_square = lower_prime**2, upper_prime**2
        if lower_square > limit:
            break
        end = min(limit, upper_square - 1)
        current = lower_square + lower_prime
        while current <= end:
            if current % upper_prime != 0:
                total += current
            current += lower_prime
        current = (lower_square // upper_prime + 1) * upper_prime
        while current <= end:
            if current % lower_prime != 0:
                total += current
            current += upper_prime
    return total


@lru_cache(maxsize=128)
def problem301_oracle(exponent: int) -> int:
    """Iterate Fibonacci exactly instead of using the source's Binet formula."""
    if not 0 <= exponent <= 30:
        return -1
    previous, current = 0, 1
    for _ in range(exponent + 2):
        previous, current = current, previous + current
    # The pinned source raises the positive (phi - 1) root; for odd indices
    # that differs from Binet's signed conjugate by truncating one below F_n.
    return previous - (exponent & 1)


@lru_cache(maxsize=1)
def problem401_prefix() -> tuple[int, ...]:
    """Sieve divisor-square contributions, omitting divisor 1 as the source does."""
    contributions = [0] * 1001
    for divisor in range(2, 1001):
        square = divisor * divisor
        for multiple in range(divisor, 1001, divisor):
            contributions[multiple] += square
    prefix = [0] * 1001
    total = 0
    for value in range(1001):
        total = (total + contributions[value]) % 1_000_000_000
        prefix[value] = total
    return tuple(prefix)


@lru_cache(maxsize=128)
def problem401_oracle(limit: int) -> int:
    if not 0 <= limit <= 1_000:
        return -1
    return problem401_prefix()[limit]


@lru_cache(maxsize=8192)
def problem686_floor_sum(n: int, modulus: int, multiplier: int, offset: int) -> int:
    """Return sum(floor((multiplier*i + offset)/modulus), i=0..n-1)."""
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
        n, offset = divmod(top, modulus)
        modulus, multiplier = multiplier, modulus


@lru_cache(maxsize=4096)
def problem686_count_ge(n: int, threshold: Fraction) -> int:
    """Count j<=n with frac(j*alpha)>=threshold for exact binary64 alpha."""
    if n <= 0:
        return 0
    alpha = Fraction.from_float(0.30102999566398114)
    p, q = alpha.numerator, alpha.denominator
    scale = threshold.denominator
    modulus = q * scale
    multiplier = p * scale
    offset = q * (scale - threshold.numerator)
    # Shift i=0..n-1 to j=i+1 in both floor sums.
    return (problem686_floor_sum(n, modulus, multiplier, multiplier + offset)
            - problem686_floor_sum(n, modulus, multiplier, multiplier))


def problem686_count_interval(n: int, lower: Fraction, upper: Fraction) -> int:
    return problem686_count_ge(n, lower) - problem686_count_ge(n, upper)


@lru_cache(maxsize=1)
def problem686_round_interval() -> tuple[Fraction, Fraction]:
    """Convert source round(x, 15) comparisons to their decimal-cell bounds."""
    scale = 10**15
    source_lower, source_upper = 0.08990511143939792, 0.09342168516223506
    first = math.floor(source_lower * scale)
    while first / scale < source_lower:
        first += 1
    while (first - 1) / scale >= source_lower:
        first -= 1
    excluded = math.floor(source_upper * scale) + 1
    while excluded / scale < source_upper:
        excluded += 1
    while (excluded - 1) / scale >= source_upper:
        excluded -= 1
    # The source thresholds lie between decimal rounding cells; exact endpoint
    # ties cannot occur for a power-of-two denominator times this decimal grid.
    return Fraction(2 * first - 1, 2 * scale), Fraction(2 * excluded - 1, 2 * scale)


@lru_cache(maxsize=1)
def problem686_float_corrections() -> tuple[tuple[int, int], ...]:
    """Find rare source-float classifications that differ from exact products."""
    maximum_exponent = 200_000_000
    lower, upper = problem686_round_interval()
    # At these exponents the product is below 61 million, whose binary64
    # multiplication error is under 4e-9; this wider band captures every
    # exponent where rounded source arithmetic can differ from exact products.
    epsilon = Fraction(1, 10_000_000)
    bands = ((lower - epsilon, lower + epsilon), (upper - epsilon, upper + epsilon))
    candidates: set[int] = set()
    before_source_start = 89
    for band_lower, band_upper in bands:
        total = (problem686_count_interval(maximum_exponent, band_lower, band_upper)
                 - problem686_count_interval(before_source_start, band_lower, band_upper))
        for rank in range(1, total + 1):
            lo, hi = 90, maximum_exponent
            while lo < hi:
                mid = (lo + hi) // 2
                count = (problem686_count_interval(mid, band_lower, band_upper)
                         - problem686_count_interval(before_source_start, band_lower, band_upper))
                if count >= rank:
                    hi = mid
                else:
                    lo = mid + 1
            candidates.add(lo)

    alpha = Fraction.from_float(0.30102999566398114)
    source_lower, source_upper = 0.08990511143939792, 0.09342168516223506
    corrections = []
    for exponent in sorted(candidates):
        exact_product = exponent * alpha
        exact_fraction = exact_product - exact_product.numerator // exact_product.denominator
        baseline = lower <= exact_fraction < upper
        product = exponent * 0.30102999566398114
        source_fraction = round(product - int(product), 15)
        source_hit = source_lower <= source_fraction < source_upper
        if source_hit != baseline:
            corrections.append((exponent, int(source_hit) - int(baseline)))
    return tuple(corrections)


@lru_cache(maxsize=8192)
def problem686_hit_count(exponent: int) -> int:
    if exponent < 90:
        return 0
    lower, upper = problem686_round_interval()
    baseline = (problem686_count_interval(exponent, lower, upper)
                - problem686_count_interval(89, lower, upper))
    corrections = problem686_float_corrections()
    return baseline + sum(delta for at, delta in corrections if at <= exponent)


@lru_cache(maxsize=128)
def problem686_oracle(occurrence: int) -> int:
    """Binary-search a floor-sum count, independent of the source jump walk."""
    if not 1 <= occurrence <= 678_910:
        return -1
    lo, hi = 90, 200_000_000
    while lo < hi:
        mid = (lo + hi) // 2
        if problem686_hit_count(mid) >= occurrence:
            hi = mid
        else:
            lo = mid + 1
    return lo


@lru_cache(maxsize=128)
def problem191_oracle(days: int) -> int:
    """Count strings with an iterative DP over the executable source states."""
    if not 0 <= days <= 65:
        return -1
    states = {(0, 0): 1}
    for _ in range(days):
        following: dict[tuple[int, int], int] = {}
        for (absent, late), count in states.items():
            if late < 2:
                key = (absent, late + 1)
                following[key] = following.get(key, 0) + count
            if absent < 1:
                key = (absent + 1, 0)
                following[key] = following.get(key, 0) + count
            key = (absent, 0)
            following[key] = following.get(key, 0) + count
        states = following
    return sum(states.values())


@lru_cache(maxsize=128)
def problem135_oracle(limit: int) -> int:
    if limit > 1_000_000:
        return -1
    if limit < 0:
        return 0
    counts = problem135_136_counts(limit)
    return sum(counts[number] == 10 for number in range(1, limit + 1))


@lru_cache(maxsize=128)
def problem136_oracle(limit: int) -> int:
    if limit > 100_000:
        return -1
    if limit <= 0:
        return 0
    counts = problem135_136_counts(limit - 1)
    return sum(count == 1 for count in counts[1:limit])


@lru_cache(maxsize=128)
def problem137_oracle(index: int) -> int:
    """Use fast-doubling Fibonacci values to check the iterative source port."""
    if not 1 <= index <= 23:
        return -1
    return fibonacci_pair(2 * index)[0] * fibonacci_pair(2 * index + 1)[0]


@lru_cache(maxsize=128)
def problem129_oracle(limit: int) -> int:
    """Find the threshold crossing from multiplicative orders modulo 9n."""
    if not 1 <= limit <= 1_000_000:
        return -1

    def repunit_order(divisor: int) -> int:
        if divisor == 1:
            return 2  # The pinned helper starts with remainder=1 and index=1.
        if divisor % 2 == 0 or divisor % 5 == 0:
            return 0
        modulus = 9 * divisor
        power, exponent = 10 % modulus, 1
        while power != 1:
            power = (power * 10) % modulus
            exponent += 1
        return exponent

    candidate = limit - 1
    if candidate % 2 == 0:
        candidate += 1
    while repunit_order(candidate) <= limit:
        candidate += 2
    return candidate


@lru_cache(maxsize=128)
def problem119_oracle(index: int) -> int:
    if not 1 <= index <= 30:
        return -1
    candidates = []
    for base in range(2, 100):
        value = base**2
        for _exponent in range(2, 100):
            if value > I64_MAX:
                break
            if sum(map(int, str(value))) == base:
                candidates.append(value)
            value *= base
    candidates.sort()
    return candidates[index - 1] if len(candidates) >= index else -1


@lru_cache(maxsize=128)
def problem120_oracle(limit: int) -> int:
    if not 0 <= limit <= 1000:
        return -1
    return sum(2 * a * ((a - 1) // 2) for a in range(3, limit + 1))


@lru_cache(maxsize=128)
def problem123_oracle(limit: int) -> int:
    """Generate primes by trial division and inspect only odd-index terms."""
    if limit > 10_000_000_000:
        return -1
    if 4 > limit:
        return 1
    primes = [2]
    candidate = 3
    while len(primes) <= 25_997:
        if all(candidate % prime for prime in primes if prime <= math.isqrt(candidate)):
            primes.append(candidate)
            n = len(primes)
            if n % 2 == 1 and 2 * candidate * n > limit:
                return n
        candidate += 2
    return -1


@lru_cache(maxsize=128)
def problem121_oracle(turns: int) -> int:
    """Compute winning integer weight by a blue-count probability DP."""
    if not 1 <= turns <= 15:
        return -1
    weights = [1]
    for turn in range(1, turns + 1):
        next_weights = [0] * (len(weights) + 1)
        for blue_count, weight in enumerate(weights):
            next_weights[blue_count] += weight * turn
            next_weights[blue_count + 1] += weight
        weights = next_weights
    winning_weight = sum(weights[blue_count] for blue_count in range(turns // 2 + 1, turns + 1))
    return math.factorial(turns + 1) // winning_weight


@lru_cache(maxsize=256)
def problem122_oracle(maximum: int) -> int:
    """Find minimum addition-chain lengths by exhaustive all-pairs search."""
    if not 0 <= maximum <= 200:
        return -1

    @lru_cache(maxsize=None)
    def minimum_length(goal: int) -> int:
        chain = [1]

        def search(remaining: int) -> bool:
            if chain[-1] == goal:
                return True
            if remaining == 0 or chain[-1] << remaining < goal:
                return False
            candidates = sorted({chain[i] + chain[j]
                                 for i in range(len(chain))
                                 for j in range(i + 1)
                                 if chain[-1] < chain[i] + chain[j] <= goal}, reverse=True)
            for candidate in candidates:
                chain.append(candidate)
                if search(remaining - 1):
                    return True
                chain.pop()
            return False

        for length in range(1, goal):
            if search(length):
                return length
        return 0

    return sum(minimum_length(goal) for goal in range(2, maximum + 1))


@lru_cache(maxsize=128)
def problem104_oracle(placeholder: int) -> int:
    """Bounded Fibonacci scan with high-precision Binet leading digits."""
    if placeholder != 0:
        return -1
    with localcontext(Context(prec=80)) as context:
        ten = Decimal(10)
        sqrt_five = context.sqrt(Decimal(5))
        phi = (Decimal(1) + sqrt_five) / 2
        log_phi = context.ln(phi) / context.ln(ten)
        log_sqrt_five = context.ln(sqrt_five) / context.ln(ten)
        previous, current = 1, 1
        for index in range(3, 1_000_003):
            previous, current = current, (previous + current) % 1_000_000_000
            digits = f"{current:09d}"
            if len(set(digits)) != 9 or "0" in digits:
                continue
            logarithm = index * log_phi - log_sqrt_five
            fractional = logarithm - int(logarithm)
            leading = int(context.power(ten, fractional + 8))
            leading_digits = f"{leading:09d}"
            if len(set(leading_digits)) == 9 and "0" not in leading_digits:
                return index
    return -1


@lru_cache(maxsize=128)
def problem114_oracle(length: int) -> int:
    """Count rows by their first item: grey square or a leading red block."""
    if not 0 <= length <= 50:
        return -1
    ways = [0] * (length + 1)
    ways[0] = 1
    for row in range(1, length + 1):
        ways[row] = ways[row - 1]
        for block_length in range(3, row + 1):
            ways[row] += 1 if block_length == row else ways[row - block_length - 1]
    return ways[length]


@lru_cache(maxsize=128)
def problem116_oracle(length: int) -> int:
    """Use one-dimensional suffix tilings for each single colored tile size."""
    if not 0 <= length <= 91:
        return -1
    total = 0
    for tile_length in (2, 3, 4):
        ways = [0] * (length + 1)
        ways[0] = 1
        for row in range(1, length + 1):
            ways[row] = ways[row - 1]
            if row >= tile_length:
                ways[row] += ways[row - tile_length]
        total += ways[length] - 1
    return total


@lru_cache(maxsize=128)
def problem117_oracle(length: int) -> int:
    """Independent first-tile dynamic program for mixed lengths 1 through 4."""
    if not 0 <= length <= 67:
        return -1
    ways = [0] * (length + 1)
    ways[0] = 1
    for row in range(1, length + 1):
        ways[row] = sum(ways[row - tile] for tile in range(1, 5) if tile <= row)
    return ways[length]


@lru_cache(maxsize=16)
def problem111_oracle(number: int) -> int:
    """Enumerate source-selected digit patterns with independent Miller-Rabin primality."""
    if not 1_000 <= number <= 10_000_000_000:
        return -1
    sieve_limit = math.isqrt(number) + 1
    sieve = bytearray(b"\x01") * (sieve_limit + 1)
    sieve[0:2] = b"\x00\x00"
    for prime in range(2, math.isqrt(sieve_limit) + 1):
        if sieve[prime]:
            sieve[prime * prime:sieve_limit + 1:prime] = b"\x00" * (
                ((sieve_limit - prime * prime) // prime) + 1
            )
    sieve_primes = {value for value in range(2, sieve_limit + 1) if sieve[value]}

    def source_selected_prime(value: int) -> bool:
        if value == 1:
            return True
        if value in sieve_primes:
            return False
        return is_prime_miller_rabin_problem27(value)

    width = len(str(number)) - 1
    total = 0
    for repeated in range(1, 10):
        for last in range(1, 10):
            value = int(f"{repeated}{'0' * (width - 2)}{last}")
            if source_selected_prime(value):
                total += value

    one_digit: set[int] = set()
    for repeated in range(1, 10):
        for position in range(width):
            for replacement in range(10):
                digits = [repeated] * width
                digits[position] = replacement
                value = int("".join(map(str, digits)))
                if source_selected_prime(value):
                    one_digit.add(repeated)
                    total += value

    repeated_two = width - 2
    for repeated in range(1, 10):
        if repeated in one_digit:
            continue
        for first_position in range(repeated_two + 1):
            for gap in range(repeated_two - first_position + 1):
                second_position = first_position + gap + 1
                for first_replacement in range(10):
                    if first_replacement == 0 and first_position == 0:
                        continue
                    for second_replacement in range(10):
                        digits = [repeated] * width
                        digits[first_position] = first_replacement
                        digits[second_position] = second_replacement
                        value = int("".join(map(str, digits)))
                        if source_selected_prime(value):
                            total += value
    return total


@lru_cache(maxsize=128)
def euler_totient_oracle(n: int) -> int:
    """Count coprime values directly, independently of factorization ports."""
    if not 1 <= n <= 1_000_000:
        return -1
    return sum(math.gcd(value, n) == 1 for value in range(1, n + 1))


def oracle(algorithm: str, n: int) -> int:
    if algorithm == "magic_square":
        return magic_square_oracle(n)
    if algorithm == "trial_division_factorizer":
        return trial_division_factorizer_oracle(n)
    if algorithm == "mersenne_primes":
        return mersenne_primes_oracle(n)
    if algorithm == "binary_palindrome_check":
        if not -(2**31) <= n <= 2**31 - 1:
            return -1
        if n < 0:
            return 0
        bits = bin(n)[2:]
        return int(bits == bits[::-1])
    if algorithm == "sum_multiples_inclusion_exclusion":
        return sum_multiples_inclusion_exclusion_oracle(n)
    if algorithm == "problem12_sol1":
        return problem12_sol1_oracle(n)
    if algorithm == "all_ones_sequence":
        return all_ones_sequence_oracle(n)
    if algorithm == "all_twos_sequence":
        return all_twos_sequence_oracle(n)
    if algorithm == "all_threes_sequence":
        return all_threes_sequence_oracle(n)
    if algorithm == "cubes_sequence":
        return cubes_sequence_oracle(n)
    if algorithm == "count_set_bits":
        return count_set_bits_oracle(n)
    if algorithm == "count_leading_zeros":
        return count_leading_zeros_oracle(n)
    if algorithm == "clear_leftmost_set_bit":
        return clear_leftmost_set_bit_oracle(n)
    if algorithm == "clear_lowest_set_bit":
        return clear_lowest_set_bit_oracle(n)
    if algorithm == "sum_of_odd_numbers":
        return sum_of_odd_numbers_oracle(n)
    if algorithm == "carmichael_number":
        return carmichael_number_oracle(n)
    if algorithm == "evil_number":
        return evil_number_oracle(n)
    if algorithm == "keith_number":
        return keith_number_oracle(n)
    if algorithm == "kynea_numbers":
        return kynea_numbers_oracle(n)
    if algorithm == "padovan_sequence":
        return padovan_sequence_oracle(n)
    if algorithm == "pell_number":
        return pell_number_oracle(n)
    if algorithm == "perrin_number":
        return perrin_number_oracle(n)
    if algorithm == "smith_number":
        return smith_number_oracle(n)
    if algorithm == "sphenic_number":
        return sphenic_number_oracle(n)
    if algorithm == "binary_length":
        return binary_length_oracle(n)
    if algorithm == "check_even":
        return check_even_oracle(n)
    if algorithm == "is_odd":
        return is_odd_oracle(n)
    if algorithm == "leap_year":
        return leap_year_oracle(n)
    if algorithm == "gauss_easter":
        return gauss_easter_oracle(n)
    if algorithm == "twos_complement_of_binary":
        return twos_complement_of_binary_oracle(n)
    if algorithm == "liouville":
        return liouville_oracle(n)
    if algorithm == "liouville_lambda":
        if not 1 <= n <= 2_147_483_647:
            return -1
        remaining, parity = n, 0
        factor = 2
        while factor * factor <= remaining:
            exponent = 0
            while remaining % factor == 0:
                remaining //= factor
                exponent += 1
            parity ^= exponent & 1
            factor = 3 if factor == 2 else factor + 2
        if remaining > 1:
            parity ^= 1
        return -1 if parity else 1
    if algorithm == "euler_totient":
        return euler_totient_oracle(n)
    if algorithm == "byte_encoding_utils":
        return int.from_bytes(n.to_bytes(8, "little", signed=True), "big", signed=True)
    if algorithm == "problem190":
        return problem190_oracle(n)
    if algorithm == "problem111":
        return problem111_oracle(n)
    if algorithm == "problem493":
        return problem493_oracle(n)
    if algorithm == "problem191":
        return problem191_oracle(n)
    if algorithm == "problem187":
        return problem187_oracle(n)
    if algorithm == "problem180":
        return problem180_oracle(n)
    if algorithm == "problem203":
        return problem203_oracle(n)
    if algorithm == "problem205":
        return problem205_oracle(n)
    if algorithm == "problem234":
        return problem234_oracle(n)
    if algorithm == "problem301":
        return problem301_oracle(n)
    if algorithm == "problem401":
        return problem401_oracle(n)
    if algorithm == "problem686":
        return problem686_oracle(n)
    if algorithm == "problem173":
        return problem173_oracle(n)
    if algorithm == "problem145":
        return problem145_oracle(n)
    if algorithm == "problem164":
        return problem164_oracle(n)
    if algorithm == "problem142":
        return problem142_oracle(n)
    if algorithm == "problem131":
        return problem131_oracle(n)
    if algorithm == "problem138":
        return problem138_oracle(n)
    if algorithm == "problem125":
        return problem125_oracle(n)
    if algorithm == "problem135":
        return problem135_oracle(n)
    if algorithm == "problem136":
        return problem136_oracle(n)
    if algorithm == "problem137":
        return problem137_oracle(n)
    if algorithm == "problem129":
        return problem129_oracle(n)
    if algorithm == "problem119":
        return problem119_oracle(n)
    if algorithm == "problem120":
        return problem120_oracle(n)
    if algorithm == "problem123":
        return problem123_oracle(n)
    if algorithm == "problem121":
        return problem121_oracle(n)
    if algorithm == "problem122":
        return problem122_oracle(n)
    if algorithm == "problem114":
        return problem114_oracle(n)
    if algorithm == "problem116":
        return problem116_oracle(n)
    if algorithm == "problem104":
        return problem104_oracle(n)
    if algorithm == "problem117":
        return problem117_oracle(n)
    if algorithm == "problem115":
        return problem115_oracle(n)
    if algorithm == "problem112":
        return problem112_oracle(n)
    if algorithm == "problem113":
        return problem113_oracle(n)
    if algorithm == "problem109":
        return problem109_oracle(n)
    if algorithm == "problem100":
        return problem100_oracle(n)
    if algorithm == "problem101":
        return problem101_oracle(n)
    if algorithm == "problem95":
        return problem95_oracle(n)
    if algorithm == "problem94":
        return problem94_oracle(n)
    if algorithm == "problem97":
        return problem97_oracle(n)
    if algorithm == "problem92":
        return problem92_oracle(n)
    if algorithm == "problem89":
        return problem89_oracle(n)
    if algorithm == "problem91":
        return problem91_oracle(n)
    if algorithm == "problem87":
        return problem87_oracle(n)
    if algorithm == "problem85":
        return problem85_oracle(n)
    if algorithm == "problem86":
        return problem86_oracle(n)
    if algorithm == "problem79":
        return problem79_oracle(n)
    if algorithm == "problem80":
        return problem80_oracle(n)
    if algorithm == "problem78":
        return problem78_oracle(n)
    if algorithm == "problem70":
        return problem70_oracle(n)
    if algorithm == "problem75":
        return problem75_oracle(n)
    if algorithm == "problem76":
        return problem76_oracle(n)
    if algorithm == "problem77":
        return problem77_oracle(n)
    if algorithm == "problem72":
        return problem72_oracle(n)
    if algorithm == "problem73":
        return problem73_oracle(n)
    if algorithm == "problem1":
        if not 0 <= n <= 100_000:
            return -1
        # Inclusion-exclusion over arithmetic progressions, independent of the
        # ports' direct scan of every value below the limit.
        def sum_multiples(divisor: int) -> int:
            count = (n - 1) // divisor
            return divisor * count * (count + 1) // 2

        return sum_multiples(3) + sum_multiples(5) - sum_multiples(15)
    if algorithm == "problem2":
        if not 0 <= n <= 4_000_000:
            return -1
        # Even Fibonacci terms satisfy E(k+1) = 4*E(k) + E(k-1),
        # avoiding the ports' full Fibonacci recurrence.
        previous_even, current_even = 2, 8
        total = 0
        while previous_even < n:
            total += previous_even
            previous_even, current_even = current_even, 4 * current_even + previous_even
        return total
    if algorithm == "problem3":
        if not 2 <= n <= 600_851_475_143:
            return -1
        remaining, largest_factor = n, 1
        factor = 2
        while factor <= remaining // factor:
            if remaining % factor == 0:
                largest_factor = factor
                while remaining % factor == 0:
                    remaining //= factor
            factor = 3 if factor == 2 else factor + 2
        return max(largest_factor, remaining)
    if algorithm == "problem4":
        if not 1 <= n <= 3:
            return -1
        lower, upper = 10 ** (n - 1), 10**n - 1
        best = 0
        for left in range(upper, lower - 1, -1):
            for right in range(left, lower - 1, -1):
                product = left * right
                if product <= best:
                    break
                digits = str(product)
                if digits == digits[::-1]:
                    best = product
                    break
        return best
    if algorithm == "problem5":
        if not 1 <= n <= 20:
            return -1
        result = 1
        for factor in range(1, n + 1):
            result = result // math.gcd(result, factor) * factor
        return result
    if algorithm == "problem6":
        if not 0 <= n <= 100:
            return -1
        total = sum(range(1, n + 1))
        sum_squares = sum(value * value for value in range(1, n + 1))
        return total * total - sum_squares
    if algorithm == "problem7":
        if not 1 <= n <= 10_001:
            return -1
        return primes_for_problem7()[n - 1]
    if algorithm == "problem8":
        if not 1 <= n <= 13:
            return -1
        return max(math.prod(int(digit) for digit in PROBLEM8_DIGITS[start:start + n])
                   for start in range(len(PROBLEM8_DIGITS) - n + 1))
    if algorithm == "problem10":
        if not 0 <= n <= 2_000_000:
            return -1
        # Inclusive prefix at n-1 enforces the package's strict upper bound.
        return prime_sum_prefix_for_problem10()[n - 1] if n > 0 else 0
    if algorithm == "problem10_ruby_prefix":
        return problem10_ruby_prefix_oracle(n)
    if algorithm == "problem12":
        if not 0 <= n <= 500:
            return -1
        return triangular_first_at_divisor_threshold()[n]
    if algorithm == "problem26":
        if not 0 <= n <= 1000:
            return -1
        best_denominator, longest_remainder_list = 1, 0
        for denominator in range(1, n + 1):
            first_position = {}
            remainder = 1
            repeated = False
            for _ in range(n):
                if remainder in first_position:
                    repeated = True
                    break
                first_position[remainder] = len(first_position)
                remainder = remainder * 10 % denominator
            if repeated:
                # The pinned Python source compares the length of all distinct
                # remainders reached, including any preperiod and terminal zero.
                score = len(first_position)
                if score > longest_remainder_list:
                    best_denominator, longest_remainder_list = denominator, score
        return best_denominator
    if algorithm == "problem28":
        if not 0 <= n <= 100_000:
            return -1
        layers = max(0, (n + 1) // 2 - 1)
        # Closed-form sum of four diagonal corners per layer.
        return 1 + 16 * layers * (layers + 1) * (2 * layers + 1) // 6 \
            + 2 * layers * (layers + 1) + 4 * layers
    if algorithm == "problem33":
        if not 0 <= n <= 5:
            return -1
        reciprocal_product = Fraction(1, 1)
        numerator, denominator = 11, 11
        upper = 10**n
        while numerator < upper:
            while denominator <= 99:
                if (numerator != denominator and numerator % 10 == denominator // 10
                        and denominator % 10 != 0
                        and (numerator // 10) * denominator == numerator * (denominator % 10)):
                    reciprocal_product *= Fraction(denominator, numerator)
                denominator += 1
            numerator += 1
            denominator = 10
        return int(reciprocal_product)
    if algorithm == "problem38":
        if n != 0:
            return -1

        def is_pandigital(value: int) -> bool:
            digits = str(value)
            return len(digits) == 9 and set(digits) == set("123456789")

        for base in range(9999, 4999, -1):
            candidate = 100002 * base
            if is_pandigital(candidate):
                return candidate
        for base in range(333, 99, -1):
            candidate = 1002003 * base
            if is_pandigital(candidate):
                return candidate
        return -1
    if algorithm == "problem206":
        return problem206_oracle(n)
    if algorithm == "problem551":
        return problem551_oracle(n)
    if algorithm == "problem43":
        if n != 10:
            return -1
        total = 0
        for digits in permutations(range(10)):
            if (digits[3] % 2 == 0 and sum(digits[2:5]) % 3 == 0
                    and digits[5] % 5 == 0
                    and all((digits[i+4]*100 + digits[i+5]*10 + digits[i+6]) % divisor == 0
                            for i, divisor in enumerate((7, 11, 13, 17)))):
                total += int("".join(map(str, digits)))
        return total
    if algorithm == "problem52":
        if n != 0:
            return -1
        value = 1
        while True:
            signature = sorted(str(value))
            if all(sorted(str(value * multiplier)) == signature for multiplier in range(2, 7)):
                return value
            value += 1
    if algorithm == "problem13":
        # The pinned source has a fixed, no-argument data set. The scalar ABI
        # admits only the zero placeholder; other values are rejected.
        return 5_537_376_230 if n == 0 else -1
    if algorithm == "problem21":
        if not 1 <= n <= 10_000:
            return -1
        total = 0
        for value in range(1, n):
            partner = proper_divisor_sum_problem21(value)
            if partner != value and proper_divisor_sum_problem21(partner) == value:
                total += value
        return total
    if algorithm == "problem19":
        if n != 0:
            return -1
        # Calendar arithmetic oracle, independent of ports' weekday stepping.
        return sum(dt.date(year, month, 1).weekday() == 6
                   for year in range(1901, 2001) for month in range(1, 13))
    if algorithm == "problem23":
        if not 0 <= n <= 28_123:
            return -1
        return problem23_non_abundant_sum(n)
    if algorithm == "problem24":
        return 2_783_915_460 if n == 0 else -1
    if algorithm == "problem25":
        return problem25_first_indices_by_digit_count()[n - 2] if 2 <= n <= 1000 else -1
    if algorithm == "problem11_sol1":
        return problem11_sol1_oracle(n)
    if algorithm == "problem30":
        return problem30_fixed_sum() if n == 0 else -1
    if algorithm == "problem32":
        return problem32_distinct_product_sum() if n == 0 else -1
    if algorithm == "problem31":
        return problem31_recursive_ways(n) if 0 <= n <= 500 else -1
    if algorithm == "problem31_recursive":
        return problem31_recursive_ways(n) if 0 <= n <= 200 else -1
    if algorithm == "problem34":
        return problem34_fixed_sum() if n == 0 else -1
    if algorithm == "problem35":
        return problem35_circular_prime_count() if n == 0 else -1
    if algorithm == "problem37":
        return problem37_truncatable_prime_sum() if n == 0 else -1
    if algorithm == "problem36":
        if not 0 <= n <= 1_000_000:
            return -1
        return sum(value for value in problem36_double_base_palindromes() if value < n)
    if algorithm == "problem39":
        return problem39_best_perimeter(n) if 12 <= n <= 1000 else -1
    if algorithm == "problem40":
        return problem40_champernowne_digit_product() if n == 0 else -1
    if algorithm == "problem47":
        return problem47_first_consecutive_base(n) if 1 <= n <= 4 else -1
    if algorithm == "problem45":
        if not 0 <= n <= 27_693:
            return -1
        for index in range(n, 27_694):
            value = index * (2 * index - 1)
            root = math.isqrt(24 * value + 1)
            if root * root == 24 * value + 1 and (root + 1) % 6 == 0:
                return value
        return -1
    if algorithm == "problem41":
        return problem41_largest_pandigital_prime(n) if 1 <= n <= 9 else -1
    if algorithm == "problem44":
        return problem44_first_pentagonal_difference(n) if 1 <= n <= 5_000 else -1
    if algorithm == "problem46":
        return problem46_goldbach_other_counterexample() if n == 0 else -1
    if algorithm == "problem48":
        return (sum(pow(value, value) for value in range(1, 1_001)) % 10_000_000_000
                if n == 0 else -1)
    if algorithm == "problem53":
        if n != 0:
            return -1
        # Symmetric central intervals avoid reproducing the source's full scan.
        count = 0
        for row in range(1, 101):
            coefficient = 1
            for column in range(1, row // 2 + 1):
                coefficient = coefficient * (row - column + 1) // column
                if coefficient > 1_000_000:
                    count += row - 2 * column + 1
                    break
        return count
    if algorithm == "problem49":
        if n != 0:
            return -1
        prime_list = [value for value in range(1001, 10_000, 2) if problem27_is_prime(value)]
        prime_set = set(prime_list)
        solutions: set[str] = set()
        for number in prime_list:
            candidates = sorted(
                int("".join(digits))
                for digits in permutations(str(number))
                if int(digits[-1]) % 2 == 1 and int("".join(digits)) in prime_set
            )
            if len(candidates) < 3:
                continue
            for first in range(len(candidates)):
                found = False
                for second in range(first + 1, len(candidates)):
                    for third in range(second + 1, len(candidates)):
                        if (abs(candidates[first] - candidates[second])
                                == abs(candidates[second] - candidates[third])
                                and len({candidates[first], candidates[second], candidates[third]}) == 3):
                            progression = sorted((candidates[first], candidates[second], candidates[third]))
                            solutions.add("".join(str(value) for value in progression))
                            found = True
                            break
                    if found:
                        break
                if found:
                    break
        return max(map(int, solutions)) if solutions else -1
    if algorithm == "problem50":
        if not 3 <= n <= 1_000_000:
            return -1
        prime = bytearray(b"\x01") * n
        prime[0:2] = b"\x00\x00"
        for value in range(2, math.isqrt(n - 1) + 1):
            if prime[value]:
                prime[value * value:n:value] = b"\x00" * (((n - 1 - value * value) // value) + 1)
        prefix = [0]
        for value, flag in enumerate(prime):
            if flag:
                prefix.append(prefix[-1] + value)
        # Prefix-sum intervals preserve the source's traversal and later-wins ties.
        best_length, best_sum = 0, 0
        for start in range(len(prefix) - 1):
            for end in range(max(start + 1, start + best_length), len(prefix)):
                total = prefix[end] - prefix[start]
                if total >= n:
                    break
                length = end - start
                if prime[total] and length >= best_length:
                    best_length, best_sum = length, total
        return best_sum
    if algorithm == "problem55":
        if not 0 <= n <= 10_000:
            return -1
        count = 0
        for start in range(1, n):
            value = start
            for _ in range(50):
                value += int(str(value)[::-1])
                digits = str(value)
                if digits == digits[::-1]:
                    break
            else:
                count += 1
        return count
    if algorithm == "problem51":
        if n != 0:
            return -1
        # Use exact prime membership, then build each candidate family directly.
        limit = 1_000_000
        prime = bytearray(b"\x01") * limit
        prime[0:2] = b"\x00\x00"
        for value in range(2, math.isqrt(limit - 1) + 1):
            if prime[value]:
                prime[value * value:limit:value] = b"\x00" * (((limit - 1 - value * value) // value) + 1)
        filtered = {value for value in range(2, limit) if prime[value]
                    and len(str(value)) - len(set(str(value))) >= 3}
        for value in sorted(filtered):
            digits = str(value)
            for digit in dict.fromkeys(digits):
                if digits.count(digit) < 2:
                    continue
                family = {int(digits.replace(digit, str(replacement)))
                          for replacement in range(10)} & filtered
                if len(family) == 8:
                    return min(family)
        return -1
    if algorithm == "problem57":
        if n > 10_000:
            return -1
        numerator, denominator = 3, 2
        count = 0
        for _ in range(max(0, n)):
            count += len(str(numerator)) > len(str(denominator))
            numerator, denominator = numerator + 2 * denominator, numerator + denominator
        return count
    if algorithm == "problem60":
        if n != 0:
            return -1
        primes = [3, 7, 13, 19]
        while len(primes) < 1_000:
            candidate = primes[-1] + 3
            while not is_prime_miller_rabin_problem27(candidate):
                candidate += 3
            primes.append(candidate)

        @lru_cache(maxsize=None)
        def concatenations_are_prime(left: int, right: int) -> bool:
            first, second = primes[left], primes[right]
            left_concat = first * 10 ** len(str(second)) + second
            right_concat = second * 10 ** len(str(first)) + first
            return (is_prime_miller_rabin_problem27(left_concat)
                    and is_prime_miller_rabin_problem27(right_concat))

        def find_chain(chain: tuple[int, ...], start: int) -> int:
            if len(chain) == 5:
                return sum(primes[index] for index in chain)
            for index in range(start, len(primes)):
                if all(concatenations_are_prime(index, member) for member in chain):
                    result = find_chain(chain + (index,), index + 1)
                    if result:
                        return result
            return 0
        return find_chain((), 0) or -1
    if algorithm == "problem64":
        if not 0 <= n <= 10_000:
            return -1
        total = 0
        for value in range(2, n + 1):
            root = math.isqrt(value)
            if root * root == value:
                continue
            m, denominator, coefficient, period = 0, 1, root, 0
            while coefficient != 2 * root:
                m = denominator * coefficient - m
                denominator = (value - m * m) // denominator
                coefficient = (root + m) // denominator
                period += 1
            total += period % 2
        return total
    if algorithm == "problem62":
        if not 1 <= n <= 5:
            return -1
        groups: dict[tuple[int, ...], tuple[int, int]] = {}
        for base in range(8_385):
            cube = base ** 3
            signature = tuple(sorted(map(int, str(cube))))
            first, count = groups.get(signature, (cube, 0))
            count += 1
            if count == n:
                return first
            groups[signature] = first, count
        return -1
    if algorithm == "problem65":
        if not 1 <= n <= 100:
            return -1
        older, numerator = 1, 2
        for position in range(2, n + 1):
            coefficient = 2 * position // 3 if position % 3 == 0 else 1
            older, numerator = numerator, coefficient * numerator + older
        return sum(map(int, str(numerator)))
    if algorithm == "problem68":
        if not 3 <= n <= 5:
            return -1
        values = list(range(n + 1, 0, -1)) + list(range(n + 2, 2 * n + 1))
        length = 2 * n
        lines = []
        for line in range(n):
            outer = 0 if line == 0 else (2 * n - 1 if line == n - 1 else 2 * line + 1)
            left = 1 if line == 0 else 2 * line
            right = 2 if line == 0 else (1 if line == n - 1 else 2 * line + 2)
            lines.append((outer, left, right))
        for order in permutations(range(length)):
            sums = [sum(values[order[index]] for index in triple) for triple in lines]
            if (len(set(sums)) == 1
                    and values[order[lines[0][0]]] == min(values[order[triple[0]]] for triple in lines)):
                result = 0
                for triple in lines:
                    for index in triple:
                        digit = values[order[index]]
                        result = result * (100 if digit >= 10 else 10) + digit
                return result
        return -1
    if algorithm == "problem69":
        if not 1 <= n <= 1_000_000:
            return -1
        # n/phi(n) is maximized by the largest primorial that fits the limit.
        primorial = 1
        for prime in (2, 3, 5, 7, 11, 13, 17):
            if primorial * prime > n:
                break
            primorial *= prime
        return primorial
    if algorithm == "problem27":
        if not 1 <= n <= 1_000:
            return -1
        return problem27_best_product(n)
    if algorithm == "problem14":
        if not 1 <= n <= 1_000_000:
            return -1
        return collatz_best_prefix_for_problem14()[n]
    if algorithm in ("problem15", "problem15_dp"):
        if not 0 <= n <= 20:
            return -1
        # Exact binomial oracle avoids the ports' multiplicative recurrence.
        return math.comb(2 * n, n)
    if algorithm == "problem16":
        if not 0 <= n <= 1_000:
            return -1
        return sum(int(digit) for digit in str(1 << n))
    if algorithm == "problem17":
        if not 0 <= n <= 1_000:
            return -1
        ones = ("", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
                "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
                "seventeen", "eighteen", "nineteen")
        tens = ("", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety")

        def number_name(value: int) -> str:
            if value < 20:
                return ones[value]
            if value < 100:
                return tens[value // 10] + ("-" + ones[value % 10] if value % 10 else "")
            if value < 1_000:
                remainder = value % 100
                return (ones[value // 100] + " hundred"
                        + (" and " + number_name(remainder) if remainder else ""))
            return "one thousand"

        return sum(sum(character.isalpha() for character in number_name(value))
                   for value in range(1, n + 1))
    if algorithm == "problem20":
        if not 0 <= n <= 100:
            return -1
        return sum(int(digit) for digit in str(math.factorial(n)))
    if algorithm == "endian_converter":
        if not -(2**31) <= n <= 2**31 - 1:
            return -(2**31) - 1
        # Reverse a four-byte big-endian encoding, independent of port bit masks.
        return int.from_bytes(n.to_bytes(4, "big", signed=True)[::-1], "big", signed=True)
    if algorithm == "problem9":
        if not 3 <= n <= 1000:
            return -1
        for a in range(1, n // 3 + 1):
            for b in range(a + 1, (n - a - 1) // 2 + 1):
                c = n - a - b
                if a * a + b * b == c * c:
                    return a * b * c
        return -1
    if algorithm == "collatz":
        if not 1 <= n <= 1_000_000:
            return -1
        steps = 0
        while n != 1:
            n = n // 2 if n % 2 == 0 else 3 * n + 1
            steps += 1
        return steps
    if algorithm == "digital_root":
        if n < 0:
            return -1
        while n >= 10:
            total = 0
            while n > 0:
                total += n % 10
                n //= 10
            n = total
        return n
    if algorithm == "hamming_weight":
        if not 0 <= n <= 2**32 - 1:
            return -1
        return sum((n >> bit) & 1 for bit in range(32))
    if algorithm == "reverse_bits":
        if not 0 <= n <= 2**32 - 1:
            return -1
        return int(f"{n:032b}"[::-1], 2)
    if algorithm in {"lucas_series", "lucas_series_recursive"}:
        maximum = 90 if algorithm == "lucas_series" else 25
        if not 0 <= n <= maximum:
            return -1
        previous, current = 2, 1
        for _ in range(n):
            previous, current = current, previous + current
        return previous
    if algorithm == "power_of_four":
        if not -(2**31) <= n <= 2**31 - 1:
            return -1
        return int(n > 0 and (n & (n - 1)) == 0 and (n & 0x55555555) != 0)
    if algorithm == "bitwise_complement":
        if not 0 <= n < 1_000_000_000:
            return -1
        return 1 if n == 0 else n ^ ((1 << n.bit_length()) - 1)
    if algorithm == "palindrome_number":
        if not 0 <= n <= 2**31 - 1:
            return -1
        digits = str(n)
        return int(digits == digits[::-1])
    if algorithm == "number_of_digits":
        return len(str(abs(n)))
    if algorithm == "happy_number":
        if n <= 0:
            return -1
        seen = set()
        while n != 1 and n not in seen:
            seen.add(n)
            total = 0
            while n:
                digit = n % 10
                total += digit * digit
                n //= 10
            n = total
        return int(n == 1)
    if algorithm == "automorphic_number":
        if n < 0:
            return 0
        modulus = 10 ** len(str(n))
        return int((n * n) % modulus == n)
    if algorithm == "isautomorphic":
        if not -3_037_000_499 <= n <= 3_037_000_499:
            return -1
        if n < 0:
            return 0
        modulus = 10 ** len(str(n))
        return int((n * n) % modulus == n)
    if algorithm == "lcm_sum":
        if not 1 <= n <= 65535:
            return -1
        return sum((index // math.gcd(index, n)) * n for index in range(1, n + 1))
    if algorithm == "leonardo_number":
        return 2 * fibonacci_pair(n + 1)[0] - 1 if 0 <= n <= 89 else -1
    if algorithm == "signum":
        return (n > 0) - (n < 0)
    if algorithm == "is_even":
        return int(n % 2 == 0)
    if algorithm == "double_factorial":
        if n < 0 or n > 33:
            return -1
        result = 1
        factor = n
        while factor > 1:
            result *= factor
            factor -= 2
        return result
    if algorithm == "power_of_two":
        return int(n > 0 and (n & (n - 1)) == 0)
    if algorithm == "prime_check":
        if n < 2:
            return 0
        if n > 2**31 - 1:
            return -1
        for factor in range(2, math.isqrt(n) + 1):
            if n % factor == 0:
                return 0
        return 1
    if algorithm == "perfect_number":
        if n < 2:
            return 0
        if n > 1_000_000_000_000:
            return -1
        # Compute sigma(n) from its prime factorization, independently of the
        # divisor-pair scan used by the implementations.
        remaining, sigma, factor = n, 1, 2
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
        return int(sigma - n == n)
    if algorithm == "number_of_digits":
        inputs.update(range(-1024, 1025))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -10**18, -10**17, -10, -1, 0, 1,
                       9, 10, 10**17, 10**18, I64_MAX - 1, I64_MAX])
        for power in range(1, 19):
            value = 10 ** power
            inputs.update([value - 1, value, value + 1, -value + 1, -value, -value - 1])
    if algorithm == "catalan_number":
        return math.comb(2 * n, n) // (n + 1) if 0 <= n <= 35 else -1
    if algorithm == "bell_numbers":
        if not 0 <= n <= 25:
            return -1
        # Independent oracle: sum the Stirling numbers of the second kind.
        stirling_row = [1]
        for set_size in range(1, n + 1):
            next_row = [0] * (set_size + 1)
            for subset_count in range(1, set_size + 1):
                previous_same_count = (
                    stirling_row[subset_count] if subset_count < set_size else 0
                )
                next_row[subset_count] = (
                    stirling_row[subset_count - 1]
                    + subset_count * previous_same_count
                )
            stirling_row = next_row
        return sum(stirling_row)
    if algorithm == "check_factorial":
        if n <= 0:
            return 0
        factorial_value, factor = 1, 1
        while factorial_value < n:
            factor += 1
            factorial_value *= factor
        return int(factorial_value == n)
    if algorithm == "factorial":
        return math.factorial(n) if 0 <= n <= 20 else -1
    if algorithm == "factorial_trailing_zeroes":
        if not 0 <= n <= 1_000_000_000:
            return -1
        count, power = 0, 5
        while power <= n:
            count += n // power
            power *= 5
        return count
    if algorithm == "binary_count_trailing_zeros":
        if n < 0:
            return -1
        return 0 if n == 0 else (n & -n).bit_length() - 1
    if algorithm == "trailing_zeroes":
        if n < 0:
            return -1
        return len(str(n)) - len(str(n).rstrip("0"))
    if algorithm in {"fibonacci", "fibonacci_fast"}:
        return fibonacci_pair(n)[0] if 0 <= n <= 92 else -1
    if algorithm == "tribonacci":
        if not 0 <= n <= 73:
            return -1
        if n == 0:
            return 0
        previous_three, previous_two, previous_one = 0, 1, 1
        for _ in range(3, n + 1):
            previous_three, previous_two, previous_one = (
                previous_two, previous_one, previous_three + previous_two + previous_one)
        return (previous_three, previous_two, previous_one)[n] if n < 3 else previous_one
    if algorithm == "armstrong_number":
        if n < 0:
            return 0
        digits = str(n)
        return int(sum(int(digit) ** len(digits) for digit in digits) == n)
    if algorithm == "aliquot_sum":
        if n < 0:
            return -1
        if n == 0:
            return 0
        # Multiplicative sigma formula from prime factorization, rather than a divisor scan.
        remaining, sigma, prime = n, 1, 2
        while prime * prime <= remaining:
            prime_power, term = 1, 1
            while remaining % prime == 0:
                remaining //= prime
                prime_power *= prime
                term += prime_power
            sigma *= term
            prime += 1
        if remaining > 1:
            sigma *= remaining + 1
        result = sigma - n
        return result if result <= I64_MAX else -1
    if algorithm == "sum_of_divisors":
        if not 1 <= n <= 1_000_000:
            return -1
        # Independent divisor-pair scan; ports use prime-power factorization.
        total = 0
        divisor = 1
        while divisor <= n // divisor:
            if n % divisor == 0:
                partner = n // divisor
                total += divisor
                if partner != divisor:
                    total += partner
            divisor += 1
        return total
    if algorithm == "abundant_number":
        if not 1 <= n <= 100_000_000:
            return -1
        # Multiplicative sigma oracle; ports instead scan factor pairs.
        remaining, sigma, factor = n, 1, 2
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
        return int(sigma > 2 * n)
    raise ValueError(f"no independent oracle for {algorithm}")


def corpus(algorithm: str) -> tuple[str, dict]:
    workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    rng = random.Random(20261014)
    inputs = {case["input_value"] for case in workload["cases"]}
    if algorithm == "trial_division_factorizer":
        inputs.update(range(-4, 4_097))
        inputs.update([-(2**63), -(2**31) - 1, -(2**31), -(2**31) + 1,
                       -899, -49, -2, -1, 0, 1, 2, 3, 4, 49, 899,
                       2**31 - 2, 2**31 - 1, 2**31, 2**63 - 1])
        inputs.update(rng.randrange(-(2**31) - 1, 2**31 + 2) for _ in range(64))
    elif algorithm == "mersenne_primes":
        inputs.update(range(0, 34))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "magic_square":
        workload_inputs = {case["input_value"] for case in workload["cases"]}
        if 1 not in workload_inputs or 31 not in workload_inputs:
            raise ValueError("magic_square workload must include minimum and maximum supported orders")
        inputs.update(range(-2, 34))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 30, 31, 32, 33,
                       I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(128))
    elif algorithm == "euler_totient":
        inputs.update(range(-3, 101))
        inputs.update([210, 2310, 999_983, 1_000_000, 1_000_001, I64_MIN, I64_MAX])
        inputs.update(rng.randrange(-1_000, 1_001) for _ in range(64))
    elif algorithm == "byte_encoding_utils":
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(128))
    elif algorithm == "liouville":
        inputs.update(range(-3, 10_001))
        inputs.update(rng.randrange(1, MAX_LIOUVILLE_INPUT + 1) for _ in range(128))
        inputs.update([I64_MIN, -2, -1, 0, 1, 2, 3, 4, 8, 12, 30, 60, 64,
                       72, 100, 999_983, 1_000_000, MAX_LIOUVILLE_INPUT - 1,
                       MAX_LIOUVILLE_INPUT, MAX_LIOUVILLE_INPUT + 1, I64_MAX])
    elif algorithm == "gauss_easter":
        inputs.update(range(MIN_GAUSS_EASTER_YEAR, MAX_GAUSS_EASTER_YEAR + 1))
        inputs.update([I64_MIN, -1, 0, MIN_GAUSS_EASTER_YEAR - 1,
                       MAX_GAUSS_EASTER_YEAR + 1, I64_MAX])
    elif algorithm == "leap_year":
        inputs.update(range(-4, 405))
        inputs.update([I64_MIN, -1, 0, 1, 4, 96, 97, 99, 100, 101, 399, 400,
                       401, 1900, 2000, 2100, 2400, I64_MAX - 4, I64_MAX - 3,
                       I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, I64_MAX + 1) for _ in range(256))
    elif algorithm in {"check_even", "is_odd"}:
        inputs.update(range(-1024, 1025))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MIN + 2, -3, -2, -1, 0, 1, 2, 3,
                       I64_MAX - 2, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
    elif algorithm == "binary_length":
        inputs.update(range(-4, 4097))
        for exponent in range(32):
            power = 1 << exponent
            inputs.update((power - 2, power - 1, power, power + 1, power + 2))
        inputs.update(rng.randrange(1, MAX_BINARY_LENGTH_INPUT + 1) for _ in range(512))
        inputs.update([I64_MIN, -1, 0, 1, MAX_BINARY_LENGTH_INPUT - 1,
                       MAX_BINARY_LENGTH_INPUT, MAX_BINARY_LENGTH_INPUT + 1, I64_MAX])
    elif algorithm in {"all_ones_sequence", "all_twos_sequence", "all_threes_sequence"}:
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 1000, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, I64_MAX + 1) for _ in range(256))
    elif algorithm == "cubes_sequence":
        inputs.update(range(-4, 4097))
        for index in (0, 1, 2, 3, 10, 100, 1024, 1280, 1290, MAX_CUBES_SEQUENCE_INDEX):
            inputs.update((index - 1, index, index + 1))
        inputs.update(rng.randrange(0, MAX_CUBES_SEQUENCE_INDEX + 1) for _ in range(512))
        inputs.update([I64_MIN, -1, MAX_CUBES_SEQUENCE_INDEX + 1, I64_MAX])
    elif algorithm == "count_set_bits":
        inputs.update(range(-4, 4097))
        for exponent in range(27):
            power = 1 << exponent
            inputs.update((power - 2, power - 1, power, power + 1, power + 2))
        inputs.update(rng.randrange(0, (1 << 26)) for _ in range(512))
        inputs.update([I64_MIN, -1, 0, 1, (1 << 26) - 2, (1 << 26) - 1,
                       1 << 26, I64_MAX])
    elif algorithm == "count_leading_zeros":
        inputs.update(range(-4096, 4097))
        for exponent in range(32):
            value = 1 << exponent
            inputs.update((value - 1, value, value + 1, -value - 1, -value, -value + 1))
        inputs.update(rng.randrange(-(1 << 31), 1 << 31) for _ in range(512))
        inputs.update([I64_MIN, -(1 << 31) - 1, -(1 << 31), -1, 0, 1,
                       (1 << 31) - 1, 1 << 31, I64_MAX])
    elif algorithm in {"clear_leftmost_set_bit", "clear_lowest_set_bit"}:
        inputs.update(range(-4, 4097))
        for exponent in range(31):
            bit = 1 << exponent
            inputs.update((bit - 1, bit, bit + 1, (1 << 31) - 1 - bit,
                           (1 << 31) - 1))
        inputs.update(rng.randrange(0, 1 << 31) for _ in range(512))
        inputs.update([I64_MIN, -1, 0, 1, (1 << 31) - 2,
                       (1 << 31) - 1, 1 << 31, I64_MAX])
    elif algorithm == "sum_of_odd_numbers":
        inputs.update(range(-4, 2049))
        inputs.update(rng.randrange(0, 46_341) for _ in range(512))
        inputs.update([I64_MIN, -1, 0, 1, 46_339, 46_340, 46_341, I64_MAX])
    elif algorithm == "carmichael_number":
        inputs.update(range(-3, MAX_CARMICHAEL_INPUT + 1))
        inputs.update(rng.randrange(1, MAX_CARMICHAEL_INPUT + 1) for _ in range(256))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 561, 1105, 1729, 2465,
                       2821, 6601, 8911, MAX_CARMICHAEL_INPUT,
                       MAX_CARMICHAEL_INPUT + 1, I64_MAX])
    elif algorithm == "evil_number":
        inputs.update(range(-4, 4097))
        inputs.update(rng.randrange(0, MAX_SIGNED_INT64 + 1) for _ in range(512))
        inputs.update([I64_MIN, -1, 0, 1, 3, MAX_SIGNED_INT64 - 1, MAX_SIGNED_INT64])
    elif algorithm == "keith_number":
        inputs.update(range(-4, 4097))
        inputs.update(rng.randrange(10, MAX_KEITH_INPUT + 1) for _ in range(512))
        inputs.update([I64_MIN, -1, 0, 9, 10, 14, 19, 28, 47, 61,
                       MAX_KEITH_INPUT - 1, MAX_KEITH_INPUT,
                       MAX_KEITH_INPUT + 1, I64_MAX])
    elif algorithm == "kynea_numbers":
        inputs.update(range(-4, MAX_KYNEA_INDEX + 3))
        inputs.update(rng.randrange(1, MAX_KYNEA_INDEX + 1) for _ in range(128))
        inputs.update([I64_MIN, -1, 0, 1, 2, MAX_KYNEA_INDEX,
                       MAX_KYNEA_INDEX + 1, I64_MAX])
    elif algorithm == "padovan_sequence":
        inputs.update(range(-4, MAX_PADOVAN_INDEX + 2))
        inputs.update(rng.randrange(0, MAX_PADOVAN_INDEX + 1) for _ in range(128))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, MAX_PADOVAN_INDEX,
                       MAX_PADOVAN_INDEX + 1, I64_MAX])
    elif algorithm == "pell_number":
        inputs.update(range(-4, MAX_PELL_INDEX + 2))
        inputs.update(rng.randrange(0, MAX_PELL_INDEX + 1) for _ in range(128))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 49, MAX_PELL_INDEX,
                       MAX_PELL_INDEX + 1, I64_MAX])
    elif algorithm == "perrin_number":
        inputs.update(range(-4, MAX_PERRIN_INDEX + 2))
        inputs.update(rng.randrange(0, MAX_PERRIN_INDEX + 1) for _ in range(128))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 154, MAX_PERRIN_INDEX,
                       MAX_PERRIN_INDEX + 1, I64_MAX])
    elif algorithm == "smith_number":
        inputs.update(range(-4, 4097))
        inputs.update(rng.randrange(1, MAX_SMITH_INPUT + 1) for _ in range(512))
        inputs.update([I64_MIN, -1, 0, 1, 2, 4, 22, 27, 666,
                       MAX_SMITH_INPUT - 1, MAX_SMITH_INPUT,
                       MAX_SMITH_INPUT + 1, I64_MAX])
    elif algorithm == "sphenic_number":
        inputs.update(range(-4, MAX_SPHENIC_INPUT + 1))
        inputs.update([I64_MIN, -1, 0, 1, 2, 30, 42, 70, 105,
                       MAX_SPHENIC_INPUT, MAX_SPHENIC_INPUT + 1, I64_MAX])
    elif algorithm == "liouville_lambda":
        inputs.update(range(-3, 10_001))
        inputs.update(rng.randrange(1, 2_147_483_648) for _ in range(128))
        inputs.update([I64_MIN, -2, -1, 0, 1, 2, 3, 4, 8, 12, 30, 64,
                       72, 100, 999_983, 1_000_000, 2_147_483_646,
                       2_147_483_647, 2_147_483_648, I64_MAX])
    elif algorithm == "twos_complement_of_binary":
        inputs.update(range(-3, 103))
        for width in range(1, 9):
            for bits in product("01", repeat=width):
                inputs.add(int("".join(bits)))
        for width in range(1, 17):
            inputs.add(int("1" + "0" * (width - 1)))
            inputs.add(int("1" * width))
        for _ in range(128):
            width = rng.randrange(1, 17)
            inputs.add(int("".join(rng.choice("01") for _ in range(width))))
        inputs.update([I64_MIN, I64_MAX, 102, 1009, 1_111_111_111_111_112,
                       10_000_000_000_000_000, 11_111_111_111_111_111])
    if algorithm == "problem13":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX])
    if algorithm == "problem104":
        inputs.update([-2, -1, 0, 1, 2])
    elif algorithm == "problem131":
        inputs.update(range(-3, 40))
        inputs.update([100, 999_999, 1_000_000, 1_000_001, I64_MAX])
    elif algorithm == "problem125":
        inputs.update(range(-3, 33))
        inputs.update([1000, 100_000, 100_000_000, 100_000_001, I64_MAX])
    elif algorithm == "problem114":
        inputs.update(range(-3, 54))
    elif algorithm == "problem116":
        inputs.update(range(-3, 95))
    elif algorithm == "problem119":
        inputs.update(range(-3, 35))
    elif algorithm == "problem120":
        inputs.update(range(-3, 1004))
    elif algorithm == "problem121":
        inputs.update(range(-3, 19))
    elif algorithm == "problem111":
        inputs.update({1000, 9999, 10000, 99999, 100000, 999999,
                       1000000, 9999999, 10000000, 9999999999,
                       I64_MIN, I64_MAX})
    elif algorithm == "problem122":
        inputs.update(range(-3, 204))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem123":
        inputs.update(range(-3, 33))
        inputs.update([100_000_000, 1_000_000_000, 10_000_000_000, 10_000_000_001, I64_MAX])
    elif algorithm == "problem129":
        inputs.update(range(-2, 34))
        inputs.update([100, 1000, 1_000_000, 1_000_001, I64_MAX])
    elif algorithm == "problem137":
        inputs.update(range(-3, 27))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem138":
        inputs.update(range(-3, 19))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem142":
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, I64_MAX])
    elif algorithm == "problem145":
        inputs.update(range(-3, 13))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem164":
        inputs.update(range(-3, 31))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem173":
        inputs.update(range(-3, 35))
        inputs.update([32, 100, 999_999, 1_000_000, 1_000_001, I64_MAX])
    elif algorithm == "problem190":
        inputs.update(range(-3, 19))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem493":
        inputs.update(range(-3, 74))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem191":
        inputs.update(range(-3, 70))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem187":
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 5, 6, 7, 8, 10, 30, 31,
                       100, 1_000, 100_000_000, 100_000_001, I64_MAX])
    elif algorithm == "problem180":
        inputs.update(range(-2, 13))
        inputs.update([20, 34, 35, 36, I64_MAX])
    elif algorithm == "problem203":
        inputs.update(range(-3, 56))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem205":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX])
    elif algorithm == "problem234":
        inputs.update([-1, 0, 1, 3, 4, 8, 9, 15, 16, 24, 25, 999, 1_000,
                       10_000, 100_000, 999_966_663_333, 999_966_663_334, I64_MAX])
    elif algorithm == "problem301":
        inputs.update(range(-3, 35))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem401":
        inputs.update(range(-3, 1005))
        inputs.update([I64_MIN, I64_MAX])
    elif algorithm == "problem686":
        inputs.update(range(-2, 65))
        inputs.update([100, 1_000, 56_000, 678_910, 678_911, I64_MIN, I64_MAX])
        inputs.update(rng.randrange(1, 20_001) for _ in range(32))
    elif algorithm == "problem135":
        inputs.update(range(-3, 40))
        inputs.update([1154, 1155, 10_000, 50_050, 1_000_000, 1_000_001, I64_MAX])
    elif algorithm == "problem136":
        inputs.update(range(-3, 40))
        inputs.update([100, 110, 10_000, 100_000, 100_001, I64_MAX])
    if algorithm == "lucas_series":
        inputs.update(range(-4, 96))
        inputs.update([I64_MIN, I64_MIN + 1, 89, 90, 91, I64_MAX - 1, I64_MAX])
    elif algorithm == "lucas_series_recursive":
        inputs.update(range(-4, 27))
        inputs.update([I64_MIN, I64_MIN + 1, 24, 25, 26, I64_MAX - 1, I64_MAX])
    elif algorithm == "check_factorial":
        inputs.update(range(-4, 1001))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, I64_MAX - 1, I64_MAX])
        for factorial_index in range(1, 21):
            value = math.factorial(factorial_index)
            inputs.update([value - 1, value, value + 1])
    elif algorithm == "factorial":
        inputs.update(range(-4, 26))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "sum_multiples_inclusion_exclusion":
        inputs.update(range(-4, 2049))
        inputs.update(rng.randrange(1, 100_001) for _ in range(512))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 14, 15, 16, 999, 1000,
                       1001, 99_989, 99_990, 99_991, 100_000, 100_001, I64_MAX])
    elif algorithm == "problem1":
        inputs.update(range(-4, 1025))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 14, 15, 16, 999,
                       1000, 1001, 99_999, 100_000, 100_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 100_001) for _ in range(256))
    elif algorithm == "problem2":
        inputs.update(range(-4, 65))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 7, 8, 9, 33, 34, 35,
                       143, 144, 145, 609, 610, 611, 2_584, 10_946, 46_368,
                       196_418, 832_040, 3_524_578, 3_999_999, 4_000_000,
                       4_000_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 4_000_001) for _ in range(256))
    elif algorithm == "problem3":
        inputs.update(range(-4, 1001))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 25, 97, 169, 13195,
                       600_851_475_143, 600_851_475_144, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(2, 100_000_001) for _ in range(128))
    elif algorithm == "problem70":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 20, 21, 100, 10_000,
                       100_000, 10_000_000, 10_000_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 100_001) for _ in range(16))
    elif algorithm == "problem75":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 49, 50, 51,
                       999, 1000, 1001, 49_999, 50_000, 50_001,
                       1_500_000, 1_500_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(-5, 10_001) for _ in range(24))
    elif algorithm == "problem76":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 5, 10, 30, 50, 100,
                       199, 200, 201, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 201) for _ in range(24))
    elif algorithm == "problem94":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 15, 16, 20, 50, 51, 1_000_000_000,
                       1_000_000_001, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem115":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 10, 50, 100, 101, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 101) for _ in range(24))
    elif algorithm == "problem112":
        inputs.update(range(-4, 106))
        inputs.update([I64_MIN, -1, 0, 1, 50, 80, 90, 99, 100, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem113":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 6, 10, 50, 99, 100, 101, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem100":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 20, 21, 22,
                       10**12, 10**12 + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem101":
        inputs.update(range(-4, 14))
        inputs.update([I64_MIN, -1, 0, 1, 2, 9, 10, 11, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem97":
        inputs.update(range(-4, 24))
        inputs.update([I64_MIN, -1, 0, 1, 8, 10, 18, 19, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem92":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 10, 100, 10_000,
                       9_999_999, 10_000_000, 10_000_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 10_000_001) for _ in range(32))
    elif algorithm == "problem89":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem91":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 10, 49, 50, 51, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem85":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 20, 2000, 2000000,
                       2000000000, 2000000001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 2_000_000_001) for _ in range(32))
    elif algorithm == "problem86":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 99, 100, 101, 999, 1000,
                       1001, 2000, 20_000, 1_000_000, 1_000_001,
                       I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(-5, 10_001) for _ in range(24))
    elif algorithm == "problem79":
        inputs.update([I64_MIN, -2, -1, 0, 1, 2, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem78":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 8, 9, 10, 100, 999, 1000,
                       1_000_000, 1_000_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 1001) for _ in range(16))
    elif algorithm == "problem72":
        inputs.update(range(0, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 8, 10, 100, 1000,
                       999_999, 1_000_000, 1_000_001, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem77":
        inputs.update(range(0, 33))
        inputs.update([I64_MIN, -1, 0, 1, 4, 5, 500, 1000, 5000, 38256,
                       38257, 100000, 100001, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem80":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem87":
        inputs.update([23, 24, 25, 27, 28, 29, 50, 100, 1000, 1000000,
                       49_999_999, 50_000_000, 50_000_001, I64_MAX])
    elif algorithm == "problem95":
        inputs.update(range(1, 31))
        inputs.update([I64_MIN, -1, 0, 1, 2, 6, 10, 28, 220, 284, 200000,
                       1_000_000, 1_000_001, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem109":
        inputs.update([I64_MIN, -1, 0, 1, 6, 7, 50, 100, 170, 171, 172, I64_MAX])
    elif algorithm == "problem117":
        inputs.update(range(0, 31))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 10, 50, 65, 66, 67, 68, I64_MAX])
    elif algorithm == "problem73":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 8, 10, 100, 1000,
                       11_999, 12_000, 12_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 12_001) for _ in range(32))
    elif algorithm == "problem4":
        inputs.update(range(-4, 5))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 4, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem5":
        inputs.update(range(-4, 23))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 4, 5, 6, 10, 12,
                       20, 21, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem6":
        inputs.update(range(-4, 105))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 5, 10, 100, 101,
                       I64_MAX - 1, I64_MAX])
    elif algorithm == "problem7":
        inputs.update(range(-4, 201))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 6, 100, 1000,
                       9999, 10000, 10001, 10002, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 10_002) for _ in range(128))
    elif algorithm == "problem21":
        inputs.update(range(-4, 12))
        inputs.update([I64_MIN, -1, 0, 1, 2, 219, 220, 221, 222, 283, 284,
                       285, 286, 1000, 1209, 1210, 1211, 4999, 5000, 5001,
                       9999, 10000, 10001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 10_001) for _ in range(128))
    elif algorithm in {"problem19", "problem24"}:
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem23":
        inputs.update([I64_MIN, -1, 0, 1, 11, 12, 23, 24, 25, 100,
                       20160, 20161, 28122, 28123, 28124, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 10_001) for _ in range(64))
    elif algorithm == "problem27":
        inputs.update(range(-4, 66))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 10, 25, 100, 999,
                       1000, 1001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 101) for _ in range(64))
    elif algorithm == "problem25":
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 9, 10, 50, 100,
                       999, 1000, 1001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(2, 1001) for _ in range(64))
    elif algorithm == "problem11_sol1":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem30":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem32":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem31":
        inputs.update(range(-4, 30))
        inputs.update([I64_MIN, -1, 0, 1, 2, 5, 10, 50, 100, 199, 200, 201,
                       499, 500, 501, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 501) for _ in range(64))
    elif algorithm == "problem31_recursive":
        inputs.update(range(-4, 30))
        inputs.update([I64_MIN, -1, 0, 1, 2, 5, 10, 50, 100, 199, 200, 201,
                       I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 201) for _ in range(64))
    elif algorithm in {"problem34", "problem35"}:
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem37":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem36":
        inputs.update([I64_MIN, -1, 0, 1, 2, 10, 99, 100, 584, 585, 586,
                       999, 1000, 100_000, 500_000, 999_999, 1_000_000,
                       1_000_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 1_000_001) for _ in range(64))
    elif algorithm == "problem39":
        inputs.update(range(-4, 35))
        inputs.update([I64_MIN, -1, 0, 11, 12, 15, 24, 40, 50, 90, 100,
                       180, 200, 999, 1000, 1001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(12, 1001) for _ in range(64))
    elif algorithm == "problem40":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem47":
        inputs.update(range(-4, 8))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem52":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem45":
        inputs.update(range(-4, 20))
        inputs.update([I64_MIN, -1, 0, 1, 2, 143, 144, 165, 27692, 27693,
                       27694, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 27_695) for _ in range(64))
    elif algorithm == "problem41":
        inputs.update(range(-4, 14))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                       I64_MAX - 1, I64_MAX])
    elif algorithm == "problem44":
        inputs.update(range(-4, 24))
        inputs.update([I64_MIN, -1, 0, 1, 2, 100, 1000, 4999, 5000, 5001,
                       I64_MAX - 1, I64_MAX])
    elif algorithm in {"problem46", "problem48", "problem53"}:
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem49":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem50":
        inputs.update(range(-4, 8))
        inputs.update([I64_MIN, -1, 0, 2, 3, 499, 500, 501, 999, 1000, 10_000,
                       1_000_000, 1_000_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(3, 1_000_001) for _ in range(32))
    elif algorithm == "problem55":
        inputs.update(range(-4, 12))
        inputs.update([I64_MIN, -1, 0, 1, 2, 47, 48, 196, 197, 198, 999,
                       1000, 1001, 4999, 5000, 5001, 9999, 10000, 10001,
                       I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 10_001) for _ in range(32))
    elif algorithm == "problem51":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem57":
        inputs.update(range(-4, 20))
        inputs.update([I64_MIN, -1, 0, 1, 8, 14, 100, 1000, 10000, 10001,
                       I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(-5, 10_001) for _ in range(64))
    elif algorithm == "problem60":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem62":
        inputs.update(range(-4, 9))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 6, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem64":
        inputs.update(range(-4, 20))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 5, 7, 11, 13, 9999, 10000,
                       10001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 10_001) for _ in range(32))
    elif algorithm == "problem65":
        inputs.update(range(-4, 15))
        inputs.update([I64_MIN, -1, 0, 1, 2, 9, 10, 50, 99, 100, 101,
                       I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 101) for _ in range(32))
    elif algorithm == "problem68":
        inputs.update(range(-4, 9))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 6, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem69":
        inputs.update(range(-4, 32))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 6, 9, 10, 29, 30, 31,
                       209, 210, 211, 2309, 2310, 2311, 510509, 510510, 510511,
                       999999, 1000000, 1000001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 1_000_001) for _ in range(32))
    elif algorithm == "problem29":
        inputs.update(range(-4, 106))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 5, 20, 50, 99, 100, 101,
                       I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 101) for _ in range(64))
    elif algorithm == "problem8":
        inputs.update(range(-4, 21))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 4, 12, 13, 14,
                       I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 14) for _ in range(64))
    elif algorithm == "problem10":
        inputs.update(range(-4, 513))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 10, 100, 1000,
                       1_999_999, 2_000_000, 2_000_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 2_000_001) for _ in range(128))
    elif algorithm == "problem10_ruby_prefix":
        inputs.update(range(-4, 513))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 10, 100, 1000,
                       1_999_999, 2_000_000, 2_000_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 2_000_001) for _ in range(128))
    elif algorithm == "problem12":
        inputs.update(range(-4, 31))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 5, 50, 100, 250, 499,
                       500, 501, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 501) for _ in range(64))
    elif algorithm == "problem12_sol1":
        inputs.update([I64_MIN, -1, 0, 1, 499, 500, 501, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem26":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 6, 7, 10, 20, 100,
                       999, 1000, 1001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 1001) for _ in range(64))
    elif algorithm == "problem28":
        inputs.update(range(-4, 33))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 10, 50, 100, 500,
                       1000, 1001, 100_000, 100_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 100_001) for _ in range(64))
    elif algorithm == "problem33":
        inputs.update(range(-4, 10))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 4, 5, 6, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem38":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem206":
        inputs.update([I64_MIN, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem551":
        inputs.update(range(-4, 101))
        inputs.update([I64_MIN, 1_000_000, 1_000_000_000_000_000,
                       1_000_000_000_000_001, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem43":
        inputs.update([I64_MIN, -1, 0, 1, 9, 10, 11, I64_MAX - 1, I64_MAX])
    elif algorithm == "problem14":
        inputs.update(range(-4, 201))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 13,
                       999_999, 1_000_000, 1_000_001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(1, 1_000_001) for _ in range(64))
    elif algorithm in ("problem15", "problem15_dp"):
        inputs.update(range(-4, 25))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 10, 19, 20, 21,
                       I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 21) for _ in range(64))
    elif algorithm == "problem16":
        inputs.update(range(-4, 65))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 10, 15, 999, 1000,
                       1001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 1001) for _ in range(128))
    elif algorithm == "problem17":
        inputs.update(range(-4, 128))
        inputs.update([I64_MIN, -1, 0, 1, 5, 19, 20, 21, 99, 100, 101,
                       342, 999, 1000, 1001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 1001) for _ in range(128))
    elif algorithm == "problem20":
        inputs.update(range(-4, 111))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 5, 10, 20, 99, 100,
                       101, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(0, 101) for _ in range(128))
    elif algorithm == "endian_converter":
        inputs.update([I64_MIN, -(2**31) - 1, -(2**31), -(2**31) + 1,
                       -0x1234567, -1, 0, 1, 0x01020304, 0x12345678,
                       2**31 - 2, 2**31 - 1, 2**31, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(-(2**31), 2**31) for _ in range(256))
    elif algorithm == "problem9":
        inputs.update(range(-4, 201))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 11, 12, 30, 100,
                       999, 1000, 1001, I64_MAX - 1, I64_MAX])
        inputs.update(rng.randrange(3, 1001) for _ in range(64))
    elif algorithm == "factorial_trailing_zeroes":
        inputs.update(range(-4, 10_001))
        inputs.update(rng.randrange(0, 1_000_000_001) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 4, 5, 6, 24, 25, 26,
                       124, 125, 126, 1_000_000_000, 1_000_000_001,
                       I64_MAX - 1, I64_MAX])
        power = 5
        while power <= 1_000_000_000:
            inputs.update([power - 1, power, power + 1])
            power *= 5
    elif algorithm == "binary_count_trailing_zeros":
        inputs.update(range(-4, 65_536))
        inputs.update(rng.randrange(0, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 4, 5, 6, 8, 16,
                       2**31, 2**32, 2**32 + 1, 2**62 - 1, 2**62, I64_MAX - 1, I64_MAX])
        for bit in range(63):
            value = 1 << bit
            inputs.update([value - 1, value, value + 1])
    elif algorithm == "trailing_zeroes":
        inputs.update(range(-1024, 10_001))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 9, 10, 11, 99, 100,
                       1000, 102983100000, 10**18 - 1, 10**18, 10**18 + 1,
                       I64_MAX - 1, I64_MAX])
        for power in range(1, 19):
            value = 10**power
            inputs.update([value - 1, value, value + 1])
    elif algorithm in {"fibonacci", "fibonacci_fast"}:
        inputs.update(range(-4, 98))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "tribonacci":
        inputs.update(range(-4, 79))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "hamming_weight":
        inputs.update(range(-4, 65536))
        inputs.update(rng.randrange(0, 2**32) for _ in range(512))
        inputs.update([-1, 0, 1, 2, 3, 0x55555555, 0xAAAAAAAA,
                       1 << 31, 2**32 - 1, 2**32, I64_MAX])
        for bit in range(32):
            value = 1 << bit
            inputs.update([value - 1, value, value + 1])
    elif algorithm == "reverse_bits":
        inputs.update(range(-4, 65536))
        inputs.update(rng.randrange(0, 2**32) for _ in range(512))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 0x55555555, 0xAAAAAAAA,
                       1 << 31, 2**32 - 1, 2**32, I64_MAX])
        for bit in range(32):
            value = 1 << bit
            inputs.update([value - 1, value, value + 1])
    elif algorithm == "bitwise_complement":
        inputs.update(range(-8, 4097))
        inputs.update(rng.randrange(0, 1_000_000_000) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 4, 5,
                       2**29 - 1, 2**29, 2**29 + 1,
                       999_999_998, 999_999_999, 1_000_000_000,
                       2**31 - 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "binary_palindrome_check":
        inputs.update(range(-16, 4097))
        inputs.update([I64_MIN, -(2**31) - 1, -(2**31), -1, 0, 1, 2, 3, 5, 6, 7,
                       9, 10, 21, 45, 46, 85, (1 << 30) - 1, 1 << 30,
                       (1 << 30) + 1, 2**31 - 1, 2**31, I64_MAX])
        inputs.update(rng.randrange(-(2**31), 2**31) for _ in range(512))
    elif algorithm == "aliquot_sum":
        inputs.update(range(513))
        inputs.update(rng.randrange(1, 10001) for _ in range(128))
        # Positive extremes are intentionally not sent through an O(n) implementation.
        inputs.update([I64_MIN, -1000, -2])
    elif algorithm == "sum_of_divisors":
        inputs.update(range(-4, 5001))
        inputs.update(rng.randrange(1, 1_000_001) for _ in range(256))
        inputs.update([I64_MIN, -1, 0, 1, 2, 13, 64, 81, 945, 999_983,
                       1_000_000, 1_000_001, I64_MAX])
    elif algorithm == "abundant_number":
        inputs.update(range(-16, 10000))
        inputs.update(rng.randrange(1, 10_000_001) for _ in range(128))
        inputs.update([I64_MIN, -1, 0, 1, 2, 6, 12, 20, 28, 945,
                       99_999_936, 99_999_937, 100_000_000,
                       100_000_001, I64_MAX])
    elif algorithm == "armstrong_number":
        inputs.update(range(10000))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(256))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
        for case in workload["cases"]:
            n = case["input_value"]
            if n > 10000:
                inputs.update(value for value in (n - 1, n + 1) if value <= I64_MAX)
    elif algorithm == "lcm_sum":
        inputs.update(range(-8, 513))
        inputs.update(rng.randrange(1, 10001) for _ in range(192))
        inputs.update([I64_MIN, -2, -1, 65534, 65535, 65536, I64_MAX])
    elif algorithm == "leonardo_number":
        inputs.update(range(-4, 100))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "signum":
        inputs.update(range(-1024, 1025))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "is_even":
        inputs.update(range(-1024, 1025))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "double_factorial":
        inputs.update(range(-4, 41))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "power_of_two":
        inputs.update(range(-1024, 1025))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, I64_MAX - 1, I64_MAX])
        inputs.update(1 << bit for bit in range(63))
        inputs.update((1 << bit) - 1 for bit in range(1, 63))
        inputs.update((1 << bit) + 1 for bit in range(1, 63) if (1 << bit) < I64_MAX)
    elif algorithm == "prime_check":
        inputs.update(range(-1024, 10001))
        inputs.update(rng.randrange(0, 2**31) for _ in range(128))
        inputs.update([I64_MIN, -2, -1, 0, 1, 2, 3, 4, 5, 9, 25, 49,
                       115248, 115249, 2147483646, 2147483647, 2147483648, I64_MAX])
    elif algorithm == "perfect_number":
        inputs.update(range(-32, 10001))
        inputs.update(rng.randrange(2, 100_000_001) for _ in range(64))
        inputs.update([I64_MIN, -2, -1, 0, 1, 2, 5, 6, 7, 27, 28, 29,
                       495, 496, 497, 8127, 8128, 8129, 33550335,
                       33550336, 33550337, 1_000_000_000_000,
                       1_000_000_000_001, I64_MAX])
    elif algorithm == "number_of_digits":
        inputs.update(range(-1024, 1025))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -10**18, -10**17, -10, -1, 0, 1, 9, 10, 10**17, 10**18, I64_MAX - 1, I64_MAX])
        for power in range(1, 19):
            value = 10 ** power
            inputs.update([value - 1, value, value + 1, -value + 1, -value, -value - 1])
    elif algorithm == "digital_root":
        inputs.update(range(-16, 10_001))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 9, 10, 19, 38, 284,
                       999, 1000, 9999, 10**18 - 1, 10**18, 10**18 + 1,
                       I64_MAX - 1, I64_MAX])
    elif algorithm == "collatz":
        inputs.update(range(-4, 65_536))
        inputs.update(rng.randrange(1, 1_000_001) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 27, 97, 871,
                       6171, 837799, 999999, 1000000, 1000001, I64_MAX - 1, I64_MAX])
    elif algorithm == "happy_number":
        inputs.update(range(-32, 10001))
        inputs.update(rng.randrange(1, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 4, 7, 10, 19,
                       20, 23, 28, 31, 68, 70, 82, 86, 89, 97, 100, 101,
                       1000, 10**18, I64_MAX - 1, I64_MAX])
    elif algorithm == "automorphic_number":
        inputs.update(range(-32, 100001))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        known = [0, 1, 5, 6, 25, 76, 376, 625, 9376, 90625,
                 259918212890625, 740081787109376]
        for value in known:
            inputs.update([value - 1, value, value + 1])
        inputs.update([I64_MIN, I64_MIN + 1, -1, I64_MAX - 1, I64_MAX])
    elif algorithm == "isautomorphic":
        inputs.update(range(-32, 100_001))
        inputs.update(rng.randrange(-3_037_000_499, 3_037_000_500) for _ in range(256))
        known = [0, 1, 5, 6, 25, 76, 376, 625, 9376, 90625,
                 259918212890625, 740081787109376]
        for value in known:
            if value <= 3_037_000_499:
                inputs.update([value - 1, value, value + 1])
        inputs.update([I64_MIN, -3_037_000_500, -3_037_000_499,
                       3_037_000_498, 3_037_000_499, 3_037_000_500, I64_MAX])
    elif algorithm == "palindrome_number":
        inputs.update(range(-16, 100_001))
        inputs.update(rng.randrange(-1, 2**31 + 2) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 9, 10, 11, 99, 100,
                       101, 1001, 1000000001, 2147447412, 2**31 - 1,
                       2**31, I64_MAX - 1, I64_MAX])
    elif algorithm == "power_of_four":
        inputs.update(range(-1024, 10_001))
        inputs.update(rng.randrange(-(2**31) - 1, 2**31 + 2) for _ in range(512))
        inputs.update([I64_MIN, -(2**31) - 1, -(2**31), -1, 0, 1, 2, 3, 4, 8,
                       16, 32, 64, 128, 256, 1024, 1 << 29, 1 << 30,
                       2**31 - 1, 2**31, I64_MAX])
        for exponent in range(16):
            value = 4**exponent
            inputs.update([value - 1, value, value + 1])
    elif algorithm == "catalan_number":
        inputs.update(range(-4, 42))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(256))
        inputs.update([I64_MIN, -2, -1, 0, 1, 2, 3, 4, 5, 20, 25, 30,
                       34, 35, 36, 50, I64_MAX])
    elif algorithm == "bell_numbers":
        inputs.update(range(-4, 31))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 8, 15, 20,
                       23, 24, 25, 26, 27, I64_MAX - 1, I64_MAX])
    for case in workload["cases"]:
        expected = oracle(algorithm, case["input_value"])
        if case["expected_result"] != expected:
            raise ValueError(f"workload oracle mismatch: {algorithm}/{case['id']}")
    data = "".join(f"{n} {oracle(algorithm, n)}\n" for n in sorted(inputs))
    return data, workload


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, workload: dict) -> dict:
    compiler = elisa_compiler if language == "elisa" else None
    manifest = build(algorithm, language, directory, compiler=compiler, with_checker=True)
    checker = manifest["binaries"]["scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=60)
    if checked.returncode:
        raise RuntimeError(f"C ABI correctness check failed: {checked.stderr}")
    count = json.loads(checked.stdout)["cases_checked"]
    if count != len(data.splitlines()):
        raise RuntimeError("checker did not consume the entire oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    command = [sys.executable, str(ROOT / "benchmarks/run_scalar.py"),
               "--algorithm", algorithm, "--language", language,
               "--source", str(ROOT / manifest["source_path"]),
               "--executable", manifest["binaries"]["scalar_runner"]["path"],
               "--compiler", manifest["compiler"], "--compiler-version", manifest["compiler_version"],
               "--build-flags=" + manifest["build_flags"],
               "--build-command", "\n".join(shlex.join(c) for c in manifest["commands"]),
               "--samples", "1", "--warmups", "0", "--repetitions", "1",
               "--output", str(records_path)]
    recorded = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=60)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        if (record["algorithm"] != algorithm or record["implementation"]["language"] != language
                or record["workload"]["input_value"] != case["input_value"]
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or record["workload"]["input_length"] is not None
                or len(record["measurement"]["samples_ns"]) != 1
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]):
            raise RuntimeError(f"recorder result/provenance mismatch in {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "source_sha256": manifest["source_sha256"], "oracle_cases": count,
            "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
            "workload_cases": len(records), "workload_sha256": sha256_file(
                ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path), "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/scalar")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--jobs", type=int, default=3)
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    if len(set(args.algorithms)) != len(args.algorithms) or len(set(args.languages)) != len(args.languages):
        parser.error("algorithm and language selections must not contain duplicates")
    directory = args.build_dir.resolve()
    corpora = {algorithm: corpus(algorithm) for algorithm in args.algorithms}
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm in args.algorithms:
            for language in args.languages:
                output = directory / algorithm[0] / algorithm / language
                data, workload = corpora[algorithm]
                job = executor.submit(verify, algorithm, language, output,
                                      args.elisa_compiler, data, workload)
                jobs[job] = (algorithm, language)
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
                print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle cases, "
                      f"{result['workload_cases']} workload records", flush=True)
            except Exception as error:
                result = {"algorithm": algorithm, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
            results.append(result)
    report_path = (args.report or directory / "verification.json").resolve()
    report = {"checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "host": {"os": platform.system(), "architecture": platform.machine()},
              "algorithms": args.algorithms, "languages": args.languages,
              "verification_source_sha256": sha256_file(Path(__file__)),
              "build_source_sha256": sha256_file(ROOT / "benchmarks/build_scalar.py"),
              "compiler_recipes_sha256": sha256_file(ROOT / "benchmarks/build_abi.py"),
              "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_scalar.py"),
              "result_schema_sha256": sha256_file(ROOT / "benchmarks/results.schema.json"),
              "all_passed": all(result["status"] == "passed" for result in results),
              "results": sorted(results, key=lambda r: (r["algorithm"], r["language"]))}
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
