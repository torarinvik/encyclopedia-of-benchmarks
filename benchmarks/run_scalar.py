#!/usr/bin/env python3
"""Run the portable scalar benchmark runner and append JSONL records."""

from __future__ import annotations

import argparse
from array import array
import datetime as dt
import hashlib
from itertools import combinations, combinations_with_replacement, permutations, product
import json
import math
import os
import platform
import shlex
import subprocess
import sys
from fractions import Fraction
from functools import lru_cache
from pathlib import Path
from typing import Any

from fib2_oracle import expected_result as fib2_expected
from nestedloop_oracle import expected_result as nestedloop_expected
from mcgill_chomp_oracle import INVALID_RESULT as MCGILL_CHOMP_INVALID_RESULT
from mcgill_chomp_oracle import expected_result as mcgill_chomp_expected
from automotive_bitcount_oracle import ALGORITHM_NAMES as AUTOMOTIVE_BITCOUNT_ALGORITHM_NAMES
from automotive_bitcount_oracle import MAX_ITERATIONS as AUTOMOTIVE_BITCOUNT_MAX_ITERATIONS
from automotive_bitcount_oracle import REFERENCE_CHECKSUMS as AUTOMOTIVE_BITCOUNT_REFERENCE_CHECKSUMS
from automotive_bitcount_oracle import algorithm_checksums as automotive_bitcount_checksums
from automotive_bitcount_oracle import expected_result as automotive_bitcount_expected
from shootout_hash_oracle import MAX_N as SHOOTOUT_HASH_MAX_N
from shootout_hash_oracle import REFERENCE_RESULT as SHOOTOUT_HASH_REFERENCE_RESULT
from shootout_hash_oracle import expected_result as shootout_hash_expected
from freebench_pifft_oracle import FFT_SIZE as FREEBENCH_PIFFT_FFT_SIZE
from freebench_pifft_oracle import expected_result as freebench_pifft_expected
from twos_complement_of_binary_oracle import expected_result as twos_complement_of_binary_expected
from binary_length_oracle import expected_result as binary_length_expected
from liouville_oracle import expected_result as liouville_expected
from gauss_easter_oracle import expected_result as gauss_easter_expected
from leap_year_oracle import expected_result as leap_year_expected
from parity_oracle import is_odd as is_odd_expected
from scalar_sequence_oracles import all_ones_sequence as all_ones_sequence_expected
from scalar_sequence_oracles import all_threes_sequence as all_threes_sequence_expected
from scalar_sequence_oracles import all_twos_sequence as all_twos_sequence_expected
from scalar_sequence_oracles import cubes_sequence as cubes_sequence_expected
from simple_scalar_oracles import clear_leftmost_set_bit as clear_leftmost_set_bit_expected
from simple_scalar_oracles import clear_lowest_set_bit as clear_lowest_set_bit_expected
from simple_scalar_oracles import count_leading_zeros as count_leading_zeros_expected
from simple_scalar_oracles import count_set_bits as count_set_bits_expected
from simple_scalar_oracles import carmichael_number as carmichael_number_expected
from simple_scalar_oracles import evil_number as evil_number_expected
from simple_scalar_oracles import keith_number as keith_number_expected
from simple_scalar_oracles import kynea_numbers as kynea_numbers_expected
from simple_scalar_oracles import padovan_sequence as padovan_sequence_expected
from simple_scalar_oracles import pell_number as pell_number_expected
from simple_scalar_oracles import perrin_number as perrin_number_expected
from simple_scalar_oracles import smith_number as smith_number_expected
from simple_scalar_oracles import sphenic_number as sphenic_number_expected
from simple_scalar_oracles import sum_of_odd_numbers as sum_of_odd_numbers_expected
from sum_multiples_inclusion_exclusion_oracle import expected_result as sum_multiples_inclusion_exclusion_expected
from partitions_oracle import expected_result as partitions_expected
from pascal_triangle_ii_oracle import expected_result as pascal_triangle_ii_expected
from pi_generator_oracle import expected_result as pi_generator_expected
from mersenne_primes_oracle import expected_result as mersenne_primes_expected
from greatest_prime_factor_oracle import expected_result as greatest_prime_factor_expected
from magic_square_oracle import expected_result as magic_square_expected
from trial_division_factorizer_oracle import expected_result as trial_division_factorizer_expected
from pollards_rho_factorizing_oracle import MAX_INPUT as POLLARDS_RHO_MAX_INPUT
from pollards_rho_factorizing_oracle import MIN_INPUT as POLLARDS_RHO_MIN_INPUT
from pollards_rho_factorizing_oracle import expected_result as pollards_rho_factorizing_expected
from problem014_oracle import MAX_LIMIT as PROBLEM014_MAX_LIMIT
from problem014_oracle import expected_output as problem014_expected
from problem44_start_cursor_oracle import expected_result as problem44_start_cursor_expected
from problem21_pair_sum_oracle import expected_output as problem21_pair_sum_expected
from so1_oracle import expected_result as so1_expected
from multiple_of_3_or_5_term_oracle import INVALID_RESULT as MULTIPLE_OF_3_OR_5_TERM_INVALID_RESULT
from multiple_of_3_or_5_term_oracle import MAX_INPUT as MULTIPLE_OF_3_OR_5_TERM_MAX_INPUT
from multiple_of_3_or_5_term_oracle import expected_result as multiple_of_3_or_5_term_expected

ROOT = Path(__file__).resolve().parents[1]
I64_MIN = -(2**63)


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


@lru_cache(maxsize=1)
def primes_for_problem7() -> tuple[int, ...]:
    """Build the bounded prime prefix used to validate Project Euler 7 cases."""
    limit = 200_000
    prime = bytearray(b"\x01") * (limit + 1)
    prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(limit) + 1):
        if prime[value]:
            prime[value * value:limit + 1:value] = b"\x00" * (((limit - value * value) // value) + 1)
    return tuple(value for value, is_prime in enumerate(prime) if is_prime)


@lru_cache(maxsize=32)
def triangular_number_for_divisor_threshold(threshold: int) -> int:
    """Find the first triangular number with the requested exact divisor count."""
    def divisor_count(value: int) -> int:
        count = 1
        factor = 2
        while factor <= value // factor:
            exponent = 0
            while value % factor == 0:
                value //= factor
                exponent += 1
            if exponent:
                count *= exponent + 1
            factor = 3 if factor == 2 else factor + 2
        if value > 1:
            count *= 2
        return count

    index = 1
    while True:
        left, right = index, index + 1
        if index % 2 == 0:
            left //= 2
        else:
            right //= 2
        if divisor_count(left) * divisor_count(right) >= threshold:
            return index * (index + 1) // 2
        index += 1


@lru_cache(maxsize=None)
def proper_divisor_sum_for_problem21(value: int) -> int:
    """Compute d(n) from its prime factorization for workload validation."""
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


@lru_cache(maxsize=8)
def problem33_source_result(digit_len: int) -> int:
    """Model the pinned source's bounded digit-cancelling fraction product."""
    numerator, denominator, result = 11, 11, 1.0
    upper = 10**digit_len
    while numerator < upper:
        while denominator <= 99:
            if (numerator != denominator and numerator % 10 == denominator // 10
                    and denominator % 10 != 0
                    and (numerator // 10) / (denominator % 10) == numerator / denominator):
                divisor = math.gcd(numerator, denominator)
                result *= (denominator // divisor) / (numerator // divisor)
            denominator += 1
        numerator += 1
        denominator = 10
    return int(result)


@lru_cache(maxsize=1)
def problem38_source_result() -> int:
    """Evaluate the pinned fixed-input concatenated-product search."""
    def is_pandigital(value: int) -> bool:
        text = str(value)
        return len(text) == 9 and set(text) == set("123456789")

    for base in range(9999, 4999, -1):
        candidate = 100002 * base
        if is_pandigital(candidate):
            return candidate
    for base in range(333, 99, -1):
        candidate = 1002003 * base
        if is_pandigital(candidate):
            return candidate
    return -1


@lru_cache(maxsize=1)
def problem52_source_result() -> int:
    """Search the source's positive integers in order for permuted multiples."""
    value = 1
    while True:
        digits = sorted(str(value))
        if all(sorted(str(multiplier * value)) == digits for multiplier in range(2, 7)):
            return value
        value += 1


@lru_cache(maxsize=1)
def problem206_source_result(unused: int) -> int:
    """Mirror the pinned descending search for the concealed square."""
    if unused != 0:
        return -1
    candidate = 138_902_663
    while candidate >= 101_010_103:
        value = candidate * candidate
        digit = 9
        square_form = True
        while value > 0:
            if value % 10 != digit:
                square_form = False
                break
            value //= 100
            digit -= 1
        if square_form:
            return candidate * 10
        candidate -= 6 if candidate % 10 == 3 else 4
    return -1


@lru_cache(maxsize=1)
def problem43_source_result() -> int:
    """Model the pinned permutation and substring-divisibility search."""
    total = 0
    for digits in permutations(range(10)):
        if (digits[3] % 2 == 0
                and sum(digits[2:5]) % 3 == 0
                and digits[5] % 5 == 0
                and all((digits[index + 4] * 100 + digits[index + 5] * 10
                         + digits[index + 6]) % divisor == 0
                        for index, divisor in enumerate((7, 11, 13, 17)))):
            value = 0
            for digit in digits:
                value = value * 10 + digit
            total += value
    return total


@lru_cache(maxsize=None)
def problem27_is_prime(value: int) -> bool:
    """Use Miller-Rabin for expected-result validation; ports use trial division."""
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
    best_length, best_product = 0, 0
    for a in range(1 - limit, limit):
        for b in range(2, limit):
            if not problem27_is_prime(b):
                continue
            length, n = 0, 0
            while problem27_is_prime(n * n + a * n + b):
                length += 1
                n += 1
            if length > best_length:
                best_length, best_product = length, a * b
    return best_product


@lru_cache(maxsize=16)
def problem23_non_abundant_sum(limit: int) -> int:
    abundant = [value for value in range(1, limit + 1)
                if proper_divisor_sum_for_problem21(value) > value]
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
    """Build the first index for each Fibonacci digit count with big integers."""
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
def problem11_sol1_source_result() -> int:
    """Scan the pinned grid in each of its four permitted directions."""
    best = 0
    directions = ((0, 1), (1, 0), (1, 1), (1, -1))
    for row in range(20):
        for column in range(20):
            for row_step, column_step in directions:
                end_row = row + 3 * row_step
                end_column = column + 3 * column_step
                if not (0 <= end_row < 20 and 0 <= end_column < 20):
                    continue
                product = 1
                for offset in range(4):
                    product *= PROBLEM11_SOL1_GRID[row + offset * row_step][column + offset * column_step]
                if product > best:
                    best = product
    return best


@lru_cache(maxsize=128)
def problem10_ruby_prefix_source_result(max_total: int) -> int:
    """Mirror Ruby's cumulative prime prefix and strict accepted-total check."""
    if not 0 <= max_total <= 2_000_000:
        return -1

    def source_is_prime(number: int) -> bool:
        if 1 < number < 4:
            value = True
        elif number < 2 or number % 2 == 0 or number % 3 == 0:
            value = False
        else:
            value = True
        end_range = int(math.sqrt(number) + 1)
        for divisor in range(5, end_range + 1, 6):
            if number % divisor == 0 or number % (divisor + 2) == 0:
                value = False
        return value

    running_total = answer = 1
    candidate = 2
    while candidate < max_total and running_total < max_total:
        if source_is_prime(candidate):
            running_total += candidate
            if running_total < max_total:
                answer = running_total
        candidate += 1
    return answer


@lru_cache(maxsize=1)
def problem30_fixed_sum() -> int:
    """Enumerate six-digit multisets to validate the fixed fifth-power sum."""
    candidates = set()
    for digits in combinations_with_replacement(range(10), 6):
        value = sum(digit**5 for digit in digits)
        if 1_000 <= value < 1_000_000:
            if sum(int(character)**5 for character in str(value)) == value:
                candidates.add(value)
    return sum(candidates)


@lru_cache(maxsize=100)
def problem29_distinct_power_count(limit: int) -> int:
    return len({base**exponent for base in range(2, limit + 1)
                for exponent in range(2, limit + 1)})


@lru_cache(maxsize=1)
def problem32_distinct_product_sum() -> int:
    """Search multiplication identities directly for workload validation."""
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
def problem31_coin_ways(remaining: int, coin_index: int = 0) -> int:
    """Memoized recurrence over coin denominations, independent of port DP."""
    coins = (1, 2, 5, 10, 20, 50, 100, 200)
    if coin_index == len(coins):
        return int(remaining == 0)
    coin = coins[coin_index]
    return sum(problem31_coin_ways(remaining - count * coin, coin_index + 1)
               for count in range(remaining // coin + 1))


@lru_cache(maxsize=1)
def problem34_fixed_sum() -> int:
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
    count = 1  # the pinned search pre-counts 2
    for candidate in range(3, 1_000_001, 2):
        digits = str(candidate)
        if any((ord(character) - ord("0")) % 2 == 0 for character in digits):
            continue
        rotation = digits
        for _ in digits:
            if not problem27_is_prime(int(rotation)):
                break
            rotation = rotation[1:] + rotation[0]
        else:
            count += 1
    return count


@lru_cache(maxsize=1)
def problem37_truncatable_prime_sum() -> int:
    total = 0
    for candidate in range(13, 1_000_001, 2):
        if not problem27_is_prime(candidate):
            continue
        digits = str(candidate)
        if all(problem27_is_prime(int(digits[offset:]))
               and problem27_is_prime(int(digits[:len(digits) - offset]))
               for offset in range(1, len(digits))):
            total += candidate
    return total


@lru_cache(maxsize=1)
def problem36_double_base_palindromes() -> tuple[int, ...]:
    """Scan decimal values directly; ports use numeric reversal checks."""
    return tuple(value for value in range(1, 1_000_000)
                 if (str(value) == str(value)[::-1]
                     and format(value, "b") == format(value, "b")[::-1]))


@lru_cache(maxsize=1)
def problem40_champernowne_digit_product() -> int:
    product = 1
    for position in (1, 10, 100, 1_000, 10_000, 100_000, 1_000_000):
        width = 1
        block = 9
        while position > width * block:
            position -= width * block
            width += 1
            block *= 10
        number = 10 ** (width - 1) + (position - 1) // width
        digit = str(number)[(position - 1) % width]
        product *= int(digit)
    return product


def problem39_nested_side_search(limit: int) -> int:
    """Reproduce insertion order from the pinned nested-leg search."""
    counts: dict[int, int] = {}
    for base in range(1, limit + 1):
        for perpendicular in range(base, limit + 1):
            hypotenuse = math.isqrt(base * base + perpendicular * perpendicular)
            if hypotenuse * hypotenuse != base * base + perpendicular * perpendicular:
                continue
            perimeter = base + perpendicular + hypotenuse
            if perimeter <= limit:
                counts[perimeter] = counts.get(perimeter, 0) + 1
    best_perimeter, best_count = 0, 0
    for perimeter, count in counts.items():
        if count > best_count:
            best_perimeter, best_count = perimeter, count
    return best_perimeter


@lru_cache(maxsize=4)
def problem47_first_consecutive_base(distinct_count: int) -> int:
    """Use trial factorization to count distinct prime factors per value."""
    run = 0
    value = 2
    while True:
        remaining, count, factor = value, 0, 2
        while factor <= remaining // factor:
            if remaining % factor == 0:
                count += 1
                while remaining % factor == 0:
                    remaining //= factor
            factor += 1
        if remaining > 1:
            count += 1
        if count == distinct_count:
            run += 1
            if run == distinct_count:
                return value - distinct_count + 1
        else:
            run = 0
        value += 1


@lru_cache(maxsize=9)
def problem41_largest_pandigital_prime(digit_count: int) -> int:
    """Validate the bounded descending-permutation search with Miller-Rabin."""
    if sum(range(1, digit_count + 1)) % 3 == 0:
        return 0
    for digits in permutations(range(digit_count, 0, -1)):
        value = 0
        for digit in digits:
            value = value * 10 + digit
        if problem27_is_prime(value):
            return value
    return 0


@lru_cache(maxsize=16)
def problem44_first_pentagonal_difference(limit: int) -> int:
    """Model ascending lower-index then upper-index search order."""
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
def problem48_last_ten_self_powers() -> int:
    modulus = 10_000_000_000
    return sum(pow(value, value, modulus) for value in range(1, 1001)) % modulus


@lru_cache(maxsize=1)
def problem46_goldbach_other_counterexample() -> int:
    """Find the first odd composite not expressible as prime plus twice a square."""
    for value in range(9, 100_000, 2):
        if problem27_is_prime(value):
            continue
        represented = False
        for square_root in range(1, math.isqrt(value // 2) + 1):
            prime = value - 2 * square_root * square_root
            if prime >= 2 and problem27_is_prime(prime):
                represented = True
                break
        if not represented:
            return value
    return -1


@lru_cache(maxsize=1)
def problem53_combinations_over_million() -> int:
    """Reproduce the source's complete nCr loop over the fixed range."""
    return sum(1 for n in range(1, 101) for r in range(1, n + 1)
               if math.comb(n, r) > 1_000_000)


@lru_cache(maxsize=1)
def problem49_prime_permutation_progression() -> int:
    primes = [value for value in range(1001, 10_000, 2) if problem27_is_prime(value)]
    groups: dict[tuple[str, ...], list[int]] = {}
    for value in primes:
        groups.setdefault(tuple(sorted(str(value))), []).append(value)
    best = 0
    seen: set[tuple[str, ...]] = set()
    for value in primes:
        signature = tuple(sorted(str(value)))
        if signature in seen:
            continue
        seen.add(signature)
        group = groups[signature]
        for first in range(len(group)):
            found = False
            for second in range(first + 1, len(group)):
                for third in range(second + 1, len(group)):
                    if group[second] - group[first] == group[third] - group[second]:
                        best = max(best, group[first] * 100_000_000
                                   + group[second] * 10_000 + group[third])
                        found = True
                        break
                if found:
                    break
            if found:
                break
    return best


@lru_cache(maxsize=64)
def problem50_longest_consecutive_prime_sum(ceiling: int) -> int:
    """Validate the source scan and its later-wins behavior on equal lengths."""
    is_prime = bytearray(b"\x01") * ceiling
    is_prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(ceiling - 1) + 1):
        if is_prime[value]:
            is_prime[value * value:ceiling:value] = b"\x00" * (((ceiling - 1 - value * value) // value) + 1)
    primes = [value for value, flag in enumerate(is_prime) if flag]
    prefix = [0]
    for value in primes:
        prefix.append(prefix[-1] + value)
    longest, largest = 0, 0
    for start in range(len(primes)):
        first_length = max(longest, 1)
        end = start + first_length
        if end > len(primes):
            break
        if prefix[end] - prefix[start] >= ceiling:
            break
        while end <= len(primes):
            total = prefix[end] - prefix[start]
            if total >= ceiling:
                break
            if is_prime[total]:
                longest, largest = end - start, total
            end += 1
    return largest


@lru_cache(maxsize=32)
def problem55_lychrel_candidate_count(limit: int) -> int:
    """Model source order: reverse-and-add first, then check for a palindrome."""
    count = 0
    for start in range(1, limit):
        value = start
        for _ in range(50):
            value += int(str(value)[::-1])
            digits = str(value)
            if digits == digits[::-1]:
                break
        else:
            count += 1
    return count


@lru_cache(maxsize=1)
def problem51_default_prime_family() -> int:
    """Search the fixed eight-member filtered-prime replacement family."""
    limit = 1_000_000
    prime = bytearray(b"\x01") * limit
    prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(limit - 1) + 1):
        if prime[value]:
            prime[value * value:limit:value] = b"\x00" * (((limit - 1 - value * value) // value) + 1)
    filtered = set()
    for value in range(2, limit):
        if prime[value]:
            digits = str(value)
            if len(digits) - len(set(digits)) >= 3:
                filtered.add(value)
    for value in sorted(filtered):
        digits = str(value)
        repeated = [digit for digit in dict.fromkeys(digits) if digits.count(digit) >= 2]
        for digit in repeated:
            family = {int(digits.replace(digit, str(replacement)))
                      for replacement in range(10)} & filtered
            if len(family) == 8:
                return min(family)
    return -1


@lru_cache(maxsize=32)
def problem57_sqrt2_expansion_count(limit: int) -> int:
    numerator, denominator = 3, 2
    count = 0
    for _ in range(limit):
        if len(str(numerator)) > len(str(denominator)):
            count += 1
        numerator, denominator = numerator + 2 * denominator, numerator + denominator
    return count


@lru_cache(maxsize=1)
def problem60_default_prime_chain_sum() -> int:
    """Preserve the pinned ascending candidate generation and first-chain DFS."""
    primes = [3, 7, 13, 19]
    while len(primes) < 1_000:
        candidate = primes[-1] + 3
        while not problem27_is_prime(candidate):
            candidate += 3
        primes.append(candidate)

    @lru_cache(maxsize=None)
    def compatible(left: int, right: int) -> bool:
        def concatenate(first: int, second: int) -> int:
            scale = 10
            while scale <= second:
                scale *= 10
            return first * scale + second
        return (problem27_is_prime(concatenate(primes[left], primes[right]))
                and problem27_is_prime(concatenate(primes[right], primes[left])))

    def search(chain: tuple[int, ...], start: int, total: int) -> int:
        if len(chain) == 5:
            return total
        for index in range(start, len(primes)):
            if all(compatible(index, member) for member in chain):
                result = search(chain + (index,), index + 1, total + primes[index])
                if result:
                    return result
        return 0

    return search((), 0, 0) or -1


@lru_cache(maxsize=32)
def problem64_odd_period_count(limit: int) -> int:
    """Count odd square-root periods using the exact quadratic-surd recurrence."""
    total = 0
    for value in range(2, limit + 1):
        root = math.isqrt(value)
        if root * root == value:
            continue
        numerator, denominator, coefficient = 0, 1, root
        period = 0
        while coefficient != 2 * root:
            numerator = denominator * coefficient - numerator
            denominator = (value - numerator * numerator) // denominator
            coefficient = (root + numerator) // denominator
            period += 1
        total += period % 2
    return total


@lru_cache(maxsize=5)
def problem62_first_cube(target_count: int) -> int:
    groups: dict[str, tuple[int, int]] = {}
    for base in range(8_385):
        cube = base ** 3
        signature = "".join(sorted(str(cube)))
        first, count = groups.get(signature, (cube, 0))
        count += 1
        if count == target_count:
            return first
        groups[signature] = (first, count)
    return -1


@lru_cache(maxsize=100)
def problem65_e_convergent_digit_sum(index: int) -> int:
    previous, current = 1, 2
    for position in range(2, index + 1):
        coefficient = (2 * position // 3) if position % 3 == 0 else 1
        previous, current = current, coefficient * current + previous
    return sum(map(int, str(current)))


@lru_cache(maxsize=3)
def problem68_first_magic_gon(side_count: int) -> int:
    """Preserve the pinned value layout, lexicographic permutations, and first ring."""
    values = list(range(side_count + 1, 0, -1)) + list(range(side_count + 2, 2 * side_count + 1))
    length = 2 * side_count
    for indices in permutations(range(length)):
        line_sum = values[indices[0]] + values[indices[1]] + values[indices[2]]
        outer = [indices[0]]
        valid = True
        for line in range(1, side_count):
            outer_index = 2 * side_count - 1 if line == side_count - 1 else 2 * line + 1
            inner_left = 2 * line
            inner_right = 1 if line == side_count - 1 else 2 * line + 2
            if values[indices[outer_index]] + values[indices[inner_left]] + values[indices[inner_right]] != line_sum:
                valid = False
                break
            outer.append(outer_index)
        if not valid or values[indices[0]] != min(values[indices[index]] for index in outer):
            continue
        result = 0
        for line in range(side_count):
            outer_index = 0 if line == 0 else (2 * side_count - 1 if line == side_count - 1 else 2 * line + 1)
            inner_left = 1 if line == 0 else 2 * line
            inner_right = 2 if line == 0 else (1 if line == side_count - 1 else 2 * line + 2)
            for index in (outer_index, inner_left, inner_right):
                value = values[indices[index]]
                result = result * (100 if value >= 10 else 10) + value
        return result
    return -1


@lru_cache(maxsize=32)
def problem69_totient_maximizer(limit: int) -> int:
    phi = list(range(limit + 1))
    for prime in range(2, limit + 1):
        if phi[prime] == prime:
            for multiple in range(prime, limit + 1, prime):
                phi[multiple] -= phi[multiple] // prime
    best = 1
    for value in range(2, limit + 1):
        if value * phi[best] > best * phi[value]:
            best = value
    return best


@lru_cache(maxsize=32)
def problem45_first_hexagonal_pentagonal(start: int) -> int:
    for index in range(start, 27_694):
        value = index * (2 * index - 1)
        discriminant = 24 * value + 1
        root = math.isqrt(discriminant)
        if root * root == discriminant and (root + 1) % 6 == 0:
            return value
    return -1


@lru_cache(maxsize=None)
def problem14_chain_length(value: int) -> int:
    if value == 1:
        return 1
    next_value = value // 2 if value % 2 == 0 else 3 * value + 1
    return 1 + problem14_chain_length(next_value)


@lru_cache(maxsize=8)
def problem14_best_start(limit: int) -> int:
    best_start, best_length = 1, 0
    for start in range(1, limit + 1):
        length = problem14_chain_length(start)
        if length > best_length:
            best_start, best_length = start, length
    return best_start


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


@lru_cache(maxsize=16)
def problem87_source_result(limit: int) -> int:
    """Model the pinned prime-square/cube/fourth-power search with a bitset."""
    if not 24 <= limit <= 50_000_000:
        return -1
    bound = max(2, math.isqrt(limit - 24))
    prime = bytearray(b"\x01") * (bound + 1)
    prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(bound) + 1):
        if prime[value]:
            prime[value * value:bound + 1:value] = b"\x00" * (((bound - value * value) // value) + 1)
    primes = [value for value in range(2, bound + 1) if prime[value]]
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


@lru_cache(maxsize=16)
def problem95_source_result(limit: int) -> int:
    """Model the source proper-divisor chain scan and strict tie update."""
    if not 1 <= limit <= 1_000_000:
        return -1
    sums = [0] * (limit + 1)
    for divisor in range(1, limit // 2 + 1):
        for multiple in range(2 * divisor, limit + 1, divisor):
            sums[multiple] += divisor
    best_length = answer = 0
    for start in range(2, limit + 1):
        visited = {start}
        current = sums[start]
        length = 1
        while current > 1 and current <= limit and current not in visited:
            visited.add(current)
            current = sums[current]
            length += 1
        if current == start and length > best_length:
            best_length, answer = length, start
    return answer


@lru_cache(maxsize=128)
def problem109_source_result(limit: int) -> int:
    """Mirror distinct doubles and combinations-with-replacement checkout throws."""
    singles = [*range(1, 21), 25]
    doubles = [2 * score for score in range(1, 21)] + [50]
    triples = [3 * score for score in range(1, 21)]
    all_values = singles + doubles + triples + [0]
    return sum(double + first + second < limit
               for double in doubles
               for first, second in combinations_with_replacement(all_values, 2))


@lru_cache(maxsize=128)
def problem119_source_result(index: int) -> int:
    """Generate and sort the pinned signed-i64 digit-power multiset."""
    if not 1 <= index <= 30:
        return -1
    candidates = []
    for base in range(2, 100):
        value = base * base
        for _exponent in range(2, 100):
            if value > 2**63 - 1:
                break
            if sum(map(int, str(value))) == base:
                candidates.append(value)
            value *= base
    candidates.sort()
    return candidates[index - 1] if len(candidates) >= index else -1


@lru_cache(maxsize=128)
def problem120_source_result(limit: int) -> int:
    if not 0 <= limit <= 1000:
        return -1
    return sum(2 * a * ((a - 1) // 2) for a in range(3, limit + 1))


@lru_cache(maxsize=128)
def problem131_source_result(limit: int) -> int:
    if not 0 <= limit <= 1_000_000:
        return -1

    def is_prime(candidate: int) -> bool:
        if candidate < 2:
            return False
        divisor = 2
        while divisor <= candidate // divisor:
            if candidate % divisor == 0:
                return False
            divisor += 1
        return True

    count, cube_index, candidate = 0, 1, 7
    while candidate < limit:
        count += is_prime(candidate)
        cube_index += 1
        candidate += 6 * cube_index
    return count


@lru_cache(maxsize=128)
def problem125_source_result(limit: int) -> int:
    """Mirror the source's consecutive-square scan and unique-value set."""
    if not 0 <= limit <= 100_000_000:
        return -1
    palindromic_sums = set()
    first = 1
    while first * first + (first + 1) * (first + 1) < limit:
        total = first * first + (first + 1) * (first + 1)
        last = first + 2
        while total < limit:
            digits = str(total)
            if digits == digits[::-1]:
                palindromic_sums.add(total)
            total += last * last
            last += 1
        first += 1
    return sum(palindromic_sums)


@lru_cache(maxsize=128)
def problem173_source_result(limit: int) -> int:
    if not 0 <= limit <= 1_000_000:
        return -1
    total = 0
    for outer_width in range(3, limit // 4 + 2):
        minimum_inner = 1
        required_square = outer_width * outer_width - limit
        if required_square > 0:
            root = math.isqrt(required_square)
            minimum_inner = root if root * root == required_square else root + 1
        if (outer_width - minimum_inner) % 2 != 0:
            minimum_inner += 1
        largest_inner = outer_width - 2
        if minimum_inner <= largest_inner:
            total += (largest_inner - minimum_inner) // 2 + 1
    return total


@lru_cache(maxsize=128)
def problem190_source_result(n: int) -> int:
    """Mirror the pinned binary64 product order for the bounded P190 sum."""
    if not 0 <= n <= 15:
        return -1
    total = 0
    for m in range(2, n + 1):
        x1 = 2.0 / (m + 1)
        product = 1.0
        for i in range(1, m + 1):
            xi = i * x1
            product *= xi ** i
        total += math.floor(product)
    return total


@lru_cache(maxsize=16)
def problem551_source_result(n: int) -> int:
    """Model the pinned decimal-prefix jump cache with an integer state."""
    if not 1 <= n <= 1_000_000_000_000_000:
        return -1
    bases = [10**k for k in range(19)]
    memo: dict[tuple[int, int], list[tuple[int, int, int]]] = {}

    def digit_sum(value: int) -> int:
        total = 0
        while value:
            total += value % 10
            value //= 10
        return total

    def compute(value: int, k: int, index: int, target: int) -> tuple[int, int, int]:
        start = index
        prefix_digit_sum = digit_sum(value // bases[k])
        suffix = value % bases[k]
        difference = 0
        while index < target:
            index += 1
            addend = prefix_digit_sum + digit_sum(suffix)
            difference += addend
            suffix += addend
            if suffix >= bases[k]:
                break
        return difference, index - start, value + difference

    def next_term(value: int, k: int, index: int, target: int) -> tuple[int, int, int]:
        prefix_digit_sum = digit_sum(value // bases[k])
        suffix = value % bases[k]
        max_terms = target - index
        jumps = memo.setdefault((prefix_digit_sum, suffix), [])
        best = None
        for jump in jumps:
            if jump[2] <= k and jump[1] <= max_terms and (best is None or jump[1] > best[1]):
                best = jump
        if best is None:
            difference = terms = 0
        else:
            difference, terms, _ = best
            value += difference
        if terms >= max_terms or suffix + difference >= bases[k]:
            return difference, terms, value
        if k > 2:
            while True:
                extra, jumped, value = next_term(value, k - 1, index + terms, target)
                difference += extra
                terms += jumped
                if terms >= max_terms or suffix + difference >= bases[k]:
                    break
        else:
            extra, jumped, value = compute(value, k, index + terms, target)
            difference += extra
            terms += jumped
        jumps.append((difference, terms, k))
        return difference, terms, value

    value = 1
    jumped = 0
    while True:
        _, terms, value = next_term(value, 18, 1 + jumped, n)
        jumped += terms
        if jumped == n - 1:
            return value


@lru_cache(maxsize=128)
def problem493_source_result(picks: int) -> int:
    """Match the source's comb ratio, binary64 arithmetic, and nine-place format."""
    if not 0 <= picks <= 70:
        return -1
    total_combinations = math.comb(70, picks)
    missing_combinations = math.comb(60, picks) if picks <= 60 else 0
    expectation = 7 * (1 - missing_combinations / total_combinations)
    return int(f"{expectation:.9f}".replace(".", ""))


@lru_cache(maxsize=128)
def problem191_source_result(days: int) -> int:
    """Mirror the pinned memoized recursion, including its cumulative A state."""
    if not 0 <= days <= 65:
        return -1

    @lru_cache(maxsize=None)
    def count(remaining: int, absent: int, late: int) -> int:
        if absent == 2 or late == 3:
            return 0
        if remaining == 0:
            return 1
        return (count(remaining - 1, absent, late + 1)
                + count(remaining - 1, absent + 1, 0)
                + count(remaining - 1, absent, 0))

    return count(days, 0, 0)


@lru_cache(maxsize=8)
def problem187_primes_below(limit: int) -> tuple[int, ...]:
    """Build the pinned P187 prime pool with its strict sieve cutoff."""
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
def problem187_source_result(max_number: int) -> int:
    """Mirror the pinned prime-pool cutoff and two-pointer pair count."""
    if not 0 <= max_number <= 100_000_000:
        return -1
    primes = problem187_primes_below(max_number // 2)
    right = len(primes) - 1
    total = 0
    for left, prime in enumerate(primes):
        while left <= right and prime * primes[right] >= max_number:
            right -= 1
        if left > right:
            break
        total += right - left + 1
    return total


def problem180_source_result(order: int) -> int:
    """Mirror the pinned integer formulas and reduced-sum set for golden triples."""
    if not 1 <= order <= 35:
        return -1

    def reduced_sum(x_num: int, x_den: int, y_num: int, y_den: int,
                    z_num: int, z_den: int) -> tuple[int, int]:
        numerator = (x_num * y_den * z_den + y_num * x_den * z_den
                     + z_num * x_den * y_den)
        denominator = x_den * y_den * z_den
        divisor = math.gcd(numerator, denominator)
        return numerator // divisor, denominator // divisor

    def include(z_num: int, z_den: int, x_num: int, x_den: int,
                y_num: int, y_den: int, unique: set[tuple[int, int]]) -> None:
        divisor = math.gcd(z_num, z_den)
        z_num //= divisor
        z_den //= divisor
        if 0 < z_num < z_den <= order:
            unique.add(reduced_sum(x_num, x_den, y_num, y_den, z_num, z_den))

    unique: set[tuple[int, int]] = set()
    for x_num in range(1, order + 1):
        for x_den in range(x_num + 1, order + 1):
            for y_num in range(1, order + 1):
                for y_den in range(y_num + 1, order + 1):
                    # x + y = z
                    include(x_num * y_den + x_den * y_num, x_den * y_den,
                            x_num, x_den, y_num, y_den, unique)

                    # x**2 + y**2 = z**2
                    z_num_sq = x_num * x_num * y_den * y_den + x_den * x_den * y_num * y_num
                    z_den_sq = x_den * x_den * y_den * y_den
                    z_num, z_den = math.isqrt(z_num_sq), math.isqrt(z_den_sq)
                    if z_num * z_num == z_num_sq and z_den * z_den == z_den_sq:
                        include(z_num, z_den, x_num, x_den, y_num, y_den, unique)

                    # 1/x + 1/y = 1/z
                    include(x_num * y_num, x_den * y_num + x_num * y_den,
                            x_num, x_den, y_num, y_den, unique)

                    # 1/x**2 + 1/y**2 = 1/z**2
                    z_num_sq = x_num * x_num * y_num * y_num
                    z_den_sq = x_den * x_den * y_num * y_num + x_num * x_num * y_den * y_den
                    z_num, z_den = math.isqrt(z_num_sq), math.isqrt(z_den_sq)
                    if z_num * z_num == z_num_sq and z_den * z_den == z_den_sq:
                        include(z_num, z_den, x_num, x_den, y_num, y_den, unique)

    total = sum((Fraction(numerator, denominator) for numerator, denominator in unique), Fraction(0))
    return total.numerator + total.denominator


@lru_cache(maxsize=128)
def problem203_source_result(depth: int) -> int:
    """Mirror the pinned Pascal-row construction and squarefree trial scan."""
    if depth > 51:
        return -1
    coefficients = {1}
    previous = [1]
    for _ in range(2, depth + 1):
        left = [*previous, 0]
        right = [0, *previous]
        previous = [a + b for a, b in zip(left, right)]
        coefficients.update(previous)

    total = 0
    for value in coefficients:
        factor = 2
        squarefree = True
        while factor * factor <= value:
            if value % (factor * factor) == 0:
                squarefree = False
                break
            factor += 1
        if squarefree:
            total += value
    return total


@lru_cache(maxsize=8)
def problem234_primes_below(limit: int) -> tuple[int, ...]:
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
def problem234_source_result(limit: int) -> int:
    """Mirror the pinned adjacent-prime-square multiples and overlap scan."""
    if not 0 <= limit <= 999_966_663_333:
        return -1
    primes = problem234_primes_below(math.isqrt(limit) + 100)
    total = 0
    index = 0
    lower_prime = primes[0]
    while lower_prime * lower_prime <= limit:
        upper_prime = primes[index + 1]
        lower_square, upper_square = lower_prime**2, upper_prime**2
        current = lower_square + lower_prime
        while current < upper_square and current <= limit:
            total += current
            current += lower_prime
        bounded_upper = upper_square
        while bounded_upper - upper_prime > limit:
            bounded_upper -= upper_prime
        current = bounded_upper - upper_prime
        while current > lower_square:
            total += current
            current -= upper_prime
        current = 0
        while bounded_upper > current and current <= limit:
            if current <= lower_square:
                current += lower_prime * upper_prime
                continue
            if current > limit:
                break
            total -= 2 * current
            current += lower_prime * upper_prime
        index += 1
        lower_prime = upper_prime
    return total


@lru_cache(maxsize=8)
def problem205_source_result(placeholder: int) -> int:
    """Mirror the pinned dice-product frequencies and seven-place float rounding."""
    if placeholder != 0:
        return -1

    def frequencies(sides: int, dice: int) -> list[int]:
        counts = [0] * (sides * dice + 1)
        for roll in product(range(1, sides + 1), repeat=dice):
            counts[sum(roll)] += 1
        return counts

    peter = frequencies(4, 9)
    colin = frequencies(6, 6)
    wins = sum(peter[total] * sum(colin[6:total]) for total in range(9, 37))
    probability = wins / (4**9 * 6**6)
    return int(round(probability, 7) * 10_000_000)


@lru_cache(maxsize=128)
def problem301_source_result(exponent: int) -> int:
    """Mirror the pinned Binet formula and bounded integer conversion."""
    if not 0 <= exponent <= 30:
        return -1
    root_five = math.sqrt(5.0)
    phi, psi = (1.0 + root_five) / 2.0, (root_five - 1.0) / 2.0
    return int((phi ** (exponent + 2) - psi ** (exponent + 2)) / root_five)


@lru_cache(maxsize=128)
def problem401_source_result(limit: int) -> int:
    """Mirror divisor-pair construction, skipping the first (unit) divisor."""
    if not 0 <= limit <= 1_000:
        return -1
    total = 0
    for value in range(1, limit + 1):
        divisors = []
        factor = 1
        while factor * factor <= value + 1:
            if value % factor == 0:
                partner = value // factor
                divisors.append(factor)
                if partner != factor:
                    divisors.append(partner)
            factor += 1
        divisors.sort()
        total += sum(divisor * divisor for divisor in divisors[1:])
    return total % 1_000_000_000


@lru_cache(maxsize=128)
def problem686_source_result(occurrence: int) -> int:
    """Mirror the pinned +93/+196 logarithmic interval scan and rounding."""
    if not 1 <= occurrence <= 678_910:
        return -1
    log10_2 = 0.30102999566398114
    lower, upper = 0.08990511143939792, 0.09342168516223506
    exponent = 90
    found = 0
    previous = 0
    while found < occurrence:
        logarithm = exponent * log10_2
        fraction = logarithm - int(logarithm)
        difference = round(fraction, 15)
        if difference >= upper:
            exponent += 93
        elif difference < lower:
            exponent += 196
        else:
            previous = exponent
            exponent += 196
            found += 1
    return previous


@lru_cache(maxsize=128)
def problem164_source_result(digit_count: int) -> int:
    """Mirror the bounded recursive previous-two-digit source recurrence."""
    if not 0 <= digit_count <= 26:
        return -1
    if digit_count == 0:
        return 1
    if digit_count == 1:
        return 9

    @lru_cache(maxsize=None)
    def suffix_count(remaining: int, previous: int, before_previous: int) -> int:
        if remaining == 0:
            return 1
        return sum(suffix_count(remaining - 1, digit, previous)
                   for digit in range(10 - previous - before_previous))

    return sum(suffix_count(digit_count - 2, second, first)
               for first in range(1, 10)
               for second in range(10 - first))


@lru_cache(maxsize=128)
def problem145_source_result(max_power: int) -> int:
    """Mirror the pinned carry recursion for every decimal length in range."""
    if max_power > 9:
        return -1
    if max_power <= 0:
        return 0

    def count_length(length: int) -> int:
        digits = [0] * length

        def recurse(remaining: int, carry_in: int) -> int:
            if remaining == 0:
                if digits[0] == 0 or digits[-1] == 0:
                    return 0
                carry = carry_in
                for i in range(length // 2 - 1, -1, -1):
                    carry += digits[i] + digits[length - i - 1]
                    if carry % 2 == 0:
                        return 0
                    carry //= 10
                return 1
            if remaining == 1:
                if carry_in % 2 == 0:
                    return 0
                result = 0
                center = length // 2
                for digit in range(10):
                    digits[center] = digit
                    result += recurse(0, (carry_in + 2 * digit) // 10)
                return result
            right_index = (length + remaining) // 2 - 1
            left_index = (length - remaining) // 2
            result = 0
            for right_digit in range(10):
                digits[right_index] = right_digit
                parity = 1 if (carry_in + right_digit) % 2 == 0 else 0
                for left_digit in range(parity, 10, 2):
                    digits[left_index] = left_digit
                    result += recurse(remaining - 2,
                                     (carry_in + right_digit + left_digit) // 10)
            return result

        return recurse(length, 0)

    return sum(count_length(length) for length in range(1, max_power + 1)
               if (length - 1) % 4 != 0)


@lru_cache(maxsize=128)
def problem142_source_result(number_of_terms: int) -> int:
    if number_of_terms == 1:
        return 1
    if number_of_terms == 2:
        return 9
    if number_of_terms != 3:
        return -1

    def is_square(value: int) -> bool:
        return 0 <= value <= 2_500**2 and math.isqrt(value) ** 2 == value

    minimum = 2**63 - 1
    for a in range(1, 2_501):
        a_sq = a * a
        for b in range(1, 2_501):
            b_sq = b * b
            if not is_square(a_sq + b_sq):
                continue
            for c in range(max(a, b) + 1, 2_501):
                c_sq = c * c
                if minimum != 2**63 - 1 and (a_sq - b_sq + 3 * c_sq) // 2 > minimum:
                    break
                if not is_square(c_sq - b_sq) or not is_square(a_sq + c_sq):
                    continue
                x2 = a_sq + b_sq + c_sq
                y2 = a_sq - b_sq + c_sq
                z2 = c_sq - a_sq - b_sq
                if z2 > 0 and x2 % 2 == 0 and y2 % 2 == 0 and z2 % 2 == 0:
                    minimum = min(minimum, (x2 + y2 + z2) // 2)
    return -1 if minimum == 2**63 - 1 else minimum


@lru_cache(maxsize=128)
def problem138_source_result(count: int) -> int:
    """Mirror the source simultaneous Pell-pair updates for each requested term."""
    if count > 14:
        return -1
    if count <= 0:
        return 0
    m, length, total = 2, 1, 0
    for _ in range(count):
        m, length = 9 * m + 20 * length, 4 * m + 9 * length
        total += length
    return total


@lru_cache(maxsize=128)
def problem136_source_result(limit: int) -> int:
    """Mirror the source delta-descending-y traversal with saturated counters."""
    if limit > 100_000:
        return -1
    if limit <= 0:
        return 0
    solutions = [0] * limit
    max_delta = (limit + 1) // 4
    for delta in range(1, max_delta + 1):
        y = 4 * delta - 1
        while y > delta:
            n = y * (4 * delta - y)
            if n >= limit:
                break
            if solutions[n] < 2:
                solutions[n] += 1
            y -= 1
    return sum(count == 1 for count in solutions)


@lru_cache(maxsize=128)
def problem137_source_result(index: int) -> int:
    """Mirror the pinned iterative Fibonacci product for the nth nugget."""
    if not 1 <= index <= 23:
        return -1
    previous, current = 1, 1
    for _ in range(2 * index - 1):
        previous, current = current, previous + current
    return previous * current


@lru_cache(maxsize=128)
def problem135_source_result(limit: int) -> int:
    """Mirror the bounded source first-term/multiple scan and ten-count test."""
    if limit > 1_000_000:
        return -1
    if limit < 0:
        return 0
    solutions = [0] * (limit + 1)
    for first_term in range(1, limit + 1):
        n = first_term
        while n <= limit:
            quotient_sum = first_term + n // first_term
            if quotient_sum % 4 == 0:
                d = quotient_sum // 4
                if first_term > d and first_term < 4 * d and solutions[n] < 11:
                    solutions[n] += 1
            n += first_term
    return sum(count == 10 for count in solutions[1:])


@lru_cache(maxsize=128)
def problem129_source_result(limit: int) -> int:
    """Mirror the source's odd-candidate scan and one-based repunit loop."""
    if not 1 <= limit <= 1_000_000:
        return -1

    def repunit_length(divisor: int) -> int:
        if divisor % 2 == 0 or divisor % 5 == 0:
            return 0
        remainder, length = 1, 1
        while remainder != 0:
            remainder = (10 * remainder + 1) % divisor
            length += 1
        return length

    candidate = limit - 1
    if candidate % 2 == 0:
        candidate += 1
    while repunit_length(candidate) <= limit:
        candidate += 2
    return candidate


@lru_cache(maxsize=128)
def problem123_source_result(limit: int) -> int:
    """Mirror odd-index prime-remainder checks using the pinned sieve bound."""
    if limit > 10_000_000_000:
        return -1
    bound = 300_000
    prime = bytearray(b"\x01") * (bound + 1)
    prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(bound) + 1):
        if prime[value]:
            prime[value * value:bound + 1:value] = b"\x00" * (((bound - value * value) // value) + 1)
    primes = [value for value, is_prime in enumerate(prime) if is_prime]
    for n in range(1, len(primes), 2):
        if 2 * primes[n - 1] * n > limit:
            return n
    return -1


@lru_cache(maxsize=128)
def problem121_source_result(turns: int) -> int:
    """Mirror source red/blue mask enumeration with exact integer weights."""
    if not 1 <= turns <= 15:
        return -1
    winning_weight = 0
    for mask in range(1 << turns):
        blue_count = mask.bit_count()
        if blue_count <= turns // 2:
            continue
        weight = 1
        for turn in range(1, turns + 1):
            if not (mask >> (turn - 1)) & 1:
                weight *= turn
        winning_weight += weight
    return math.factorial(turns + 1) // winning_weight


@lru_cache(maxsize=128)
def problem122_source_result(maximum: int) -> int:
    """Mirror the pinned depth-first star addition-chain search."""
    if not 0 <= maximum <= 200:
        return -1

    def minimum_star_depth(goal: int) -> int:
        chain = [1]

        def search(depth: int) -> bool:
            last = chain[-1]
            for element in chain:
                candidate = element + last
                if candidate == goal:
                    return True
                if candidate > goal:
                    break
                if len(chain) < depth:
                    chain.append(candidate)
                    if search(depth):
                        return True
                    chain.pop()
            return False

        for depth in range(1, goal + 1):
            chain[:] = [1]
            if search(depth):
                return depth
        return 0

    return sum(minimum_star_depth(goal) for goal in range(2, maximum + 1))


@lru_cache(maxsize=128)
def problem104_source_result(placeholder: int) -> int:
    """Validate the fixed source search's only supported placeholder value."""
    return 329468 if placeholder == 0 else -1


@lru_cache(maxsize=128)
def problem114_source_result(length: int) -> int:
    """Mirror the pinned nested block-start recurrence for rows through 50."""
    if not 0 <= length <= 50:
        return -1
    ways = [1] * (length + 1)
    for row_length in range(3, length + 1):
        ways[row_length] = 1
        for block_length in range(3, row_length + 1):
            for block_start in range(row_length - block_length):
                ways[row_length] += ways[row_length - block_start - block_length - 1]
            ways[row_length] += 1
    return ways[length]


@lru_cache(maxsize=32)
def problem111_source_result(number: int) -> int:
    """Mirror the pinned candidate generation and full sieve-prime divisibility scan."""
    if not 1_000 <= number <= 10_000_000_000:
        return -1
    sieve_limit = math.isqrt(number) + 1
    is_prime = bytearray(b"\x01") * (sieve_limit + 1)
    is_prime[0:2] = b"\x00\x00"
    for prime in range(2, math.isqrt(sieve_limit) + 1):
        if is_prime[prime]:
            is_prime[prime * prime:sieve_limit + 1:prime] = b"\x00" * (
                ((sieve_limit - prime * prime) // prime) + 1
            )
    primes = [prime for prime in range(2, sieve_limit + 1) if is_prime[prime]]

    def source_is_prime(value: int) -> bool:
        return all(value % prime != 0 for prime in primes)

    digits = len(str(number))
    width = digits - 1
    total = 0
    for repeated in range(1, 10):
        for last in range(1, 10):
            value = int(f"{repeated}{'0' * (digits - 3)}{last}")
            if source_is_prime(value):
                total += value

    one_digit: set[int] = set()
    for repeated in range(1, 10):
        for position in range(width):
            for replacement in range(10):
                digits_list = [repeated] * width
                digits_list[position] = replacement
                value = int("".join(map(str, digits_list)))
                if source_is_prime(value):
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
                        candidate = [repeated] * width
                        candidate[first_position] = first_replacement
                        candidate[second_position] = second_replacement
                        value = int("".join(map(str, candidate)))
                        if source_is_prime(value):
                            total += value
    return total


@lru_cache(maxsize=128)
def problem116_source_result(length: int) -> int:
    """Mirror the source's separate tile-color passes and inclusive row scan."""
    if not 0 <= length <= 91:
        return -1
    total = 0
    for tile_length in (2, 3, 4):
        ways = [0] * (length + 1)
        for row_length in range(length + 1):
            ways[row_length] = 1
            for tile_start in range(row_length - tile_length + 1):
                ways[row_length] += ways[row_length - tile_start - tile_length]
        total += ways[length] - 1
    return total


@lru_cache(maxsize=128)
def problem117_source_result(length: int) -> int:
    """Mirror the pinned row/tile-start recurrence with its inclusive counts."""
    if not 0 <= length <= 67:
        return -1
    ways = [1] * (length + 1)
    for row_length in range(length + 1):
        for tile_length in range(2, 5):
            for tile_start in range(row_length - tile_length + 1):
                ways[row_length] += ways[row_length - tile_start - tile_length]
    return ways[length]


POLLARDS_RHO_CASE_IDS = frozenset({
    "two", "small_prime_3", "composite_4_returns_n", "small_prime_5",
    "small_composite_6", "prime_7_returns_n", "power_of_two_8_returns_n", "composite_9",
    "even_composite_10", "composite_12", "composite_15", "composite_21_returns_n",
    "square_25_returns_n", "square_49", "composite_91", "semiprime_8051",
    "semiprime_10403", "near_bound_46339", "maximum_safe_input", "zero_rejected_before_source",
    "one_rejected_before_source", "negative_rejected", "first_overflow_bound_rejected",
    "signed_i64_minimum_rejected", "signed_i64_maximum_rejected",
})


def validate_pollards_rho_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/C-Sharp",
        "commit": "96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c",
        "path": "Algorithms/Other/PollardsRhoFactorizing.cs",
        "symbol": "PollardsRhoFactorizing.Calculate",
        "url": "https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/PollardsRhoFactorizing.cs",
    }
    input_spec = {
        "kind": "signed_i64_scalar",
        "minimum": POLLARDS_RHO_MIN_INPUT,
        "maximum": POLLARDS_RHO_MAX_INPUT,
        "domain_reason": "Positive inputs avoid the source modulo-by-zero and nonterminating n=1 cases; the upper bound prevents overflow in signed 32-bit x*x+1.",
        "invalid_result": -1,
        "out_of_domain_result": -1,
    }
    output_spec = {
        "kind": "signed_i64_scalar",
        "meaning": "The first gcd(|x-y|, n) not equal to 1 from the pinned deterministic recurrence; this value may equal n.",
        "not_a_primality_claim": True,
        "invalid_result": -1,
    }
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-csharp-pollards-rho-factorizing-scalar-v1"
            or workload.get("algorithm") != "pollards_rho_factorizing"
            or workload.get("function_symbol") != "pollards_rho_factorizing"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("measurement") != {
                "comparison_model": "scalar_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 10,
            }
            or POLLARDS_RHO_MIN_INPUT != 2 or POLLARDS_RHO_MAX_INPUT != 46_340
            or len(case_ids) != len(POLLARDS_RHO_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != POLLARDS_RHO_CASE_IDS):
        raise ValueError("pollards_rho_factorizing workload metadata does not match its reviewed scalar contract")
    readme = (ROOT / "benchmarks" / "p" / "pollards_rho_factorizing" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or "2..46340" not in readme
            or "may equal" not in readme):
        raise ValueError("pollards_rho_factorizing README is missing its pinned source or result-domain note")
    for case in workload["cases"]:
        input_value = case.get("input_value")
        expected = case.get("expected_result")
        if (type(input_value) is not int or not -(1 << 63) <= input_value < (1 << 63)
                or type(expected) is not int
                or expected != pollards_rho_factorizing_expected(input_value)):
            raise ValueError(f"pollards_rho_factorizing workload mismatch: {case.get('id')}")


MULTIPLE_OF_3_OR_5_TERM_CASE_IDS = frozenset({
    "zero_term", "divisible_by_3_term", "divisible_by_5_term", "divisible_by_15_once",
    "nonmultiple_term", "negative_input_invalid", "above_limit_invalid",
})


def validate_multiple_of_3_or_5_term_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/MATLAB-Octave",
        "commit": "e150b77ad256de46c1ce3815c3d7945ac4fc28dc",
        "path": "project-euler/Problem1/multiple.m",
    }
    input_spec = {
        "kind": "signed_64_bit_integer",
        "value_range": [0, MULTIPLE_OF_3_OR_5_TERM_MAX_INPUT],
        "result": "return n when n is divisible by 3 or 5; otherwise return 0",
        "out_of_range_result": MULTIPLE_OF_3_OR_5_TERM_INVALID_RESULT,
    }
    output_spec = {
        "kind": "signed_64_bit_integer",
        "out_of_range_result": MULTIPLE_OF_3_OR_5_TERM_INVALID_RESULT,
    }
    cases = workload.get("cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "matlab-multiple-of-3-or-5-term-i64-scalar-v1"
            or workload.get("algorithm") != "multiple_of_3_or_5_term"
            or workload.get("function_symbol") != "multiple_of_3_or_5_term"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("measurement") != {
                "comparison_model": "scalar_call",
                "sample_count": 7,
                "warmup_rounds": 1,
                "repetitions_per_sample": 1000,
            }
            or MULTIPLE_OF_3_OR_5_TERM_MAX_INPUT != 1_000_000_000
            or MULTIPLE_OF_3_OR_5_TERM_INVALID_RESULT != -1
            or not isinstance(cases, list)
            or len(case_ids) != len(MULTIPLE_OF_3_OR_5_TERM_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != MULTIPLE_OF_3_OR_5_TERM_CASE_IDS):
        raise ValueError("multiple_of_3_or_5_term workload metadata or case IDs do not match the reviewed contract")
    readme = (ROOT / "benchmarks" / "m" / "multiple_of_3_or_5_term" / "README.md").read_text(
        encoding="utf-8")
    source_url = "https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/project-euler/Problem1/multiple.m"
    if source_url not in readme or "does not sum a range" not in readme:
        raise ValueError("multiple_of_3_or_5_term README is missing its pinned source or one-term semantics")
    for case in cases:
        input_value = case.get("input_value")
        expected = case.get("expected_result")
        if (type(input_value) is not int or not -(1 << 63) <= input_value < (1 << 63)
                or type(expected) is not int
                or expected != multiple_of_3_or_5_term_expected(input_value)):
            raise ValueError(f"multiple_of_3_or_5_term workload mismatch: {case.get('id')}")


def validate_mcgill_chomp_workload(workload: dict) -> None:
    pinned = "5d7b75df749241efa7a6e6f5be613d3fcc5cce38"
    source_url = f"https://github.com/lac-dcc/Benchmarks/blob/{pinned}/McGill/chomp/chomp.c"
    launcher_url = f"https://github.com/lac-dcc/Benchmarks/blob/{pinned}/McGill/chomp/info.sh"
    expected_ids = {
        "small_problem_size_profile_7x7", "default_profile_8x7", "below_profile_range",
        "above_profile_range", "zero_rows", "negative_rows", "signed_i64_minimum",
        "signed_i64_maximum",
    }
    cases = workload.get("cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "lac-dcc-mcgill-chomp-fixed-rectangle-i64-scalar-v1"
            or workload.get("algorithm") != "mcgill_chomp"
            or workload.get("function_symbol") != "mcgill_chomp"
            or workload.get("pinned_source") != {
                "repository": "lac-dcc/Benchmarks", "commit": pinned,
                "path": "McGill/chomp/chomp.c",
                "symbols": ["make_data", "valid_data", "make_list", "make_play", "get_good_move", "main"],
                "url": source_url,
                "license_note": "The repository snapshot declares no license, and chomp.c has no explicit license grant. The ports are independently written from the observed state recurrence and game rules.",
            }
            or workload.get("pinned_launcher") != {
                "repository": "lac-dcc/Benchmarks", "commit": pinned,
                "path": "McGill/chomp/info.sh", "bench_name": "chomp",
                "source_files": ["chomp.c"], "compile_flags": ["-lm"], "run_options": [],
            }
            or workload.get("source_bound") != {
                "mode": "main hardcodes report-game mode 2; interactive selection is disabled",
                "columns": 7, "rows": {"small_problem_size": 7, "default": 8},
                "state_representation": "One height per column, ordered left to right; valid heights are non-increasing from left to right.",
                "move_order": "Rows increase from 0, then columns increase from 0; a move at row r and column c caps every column c and to its right at height r.",
                "outcome": "A state wins iff it has a legal successor that loses. The empty board has value 1 because the previous mover took the poison square.",
                "reported_result": "Return the initial full-board value: 1 means the first player wins, 0 means the first player loses. The upstream CLI's individual move lines and prompts are excluded.",
            }
            or workload.get("input") != {
                "kind": "signed_64_bit_integer",
                "meaning": "Initial board row count selected by the launcher profile; width is fixed at 7 columns.",
                "accepted_values": [7, 8], "invalid_input_result": MCGILL_CHOMP_INVALID_RESULT,
            }
            or workload.get("output") != {
                "kind": "signed_64_bit_integer",
                "meaning": "First-player game-tree outcome for the full rectangular board: 1 for a win, 0 for a loss.",
                "invalid_input_result": MCGILL_CHOMP_INVALID_RESULT,
            }
            or workload.get("measurement") != {
                "comparison_model": "scalar_call", "sample_count": 3,
                "warmup_rounds": 0, "repetitions_per_sample": 1,
            }
            or not isinstance(cases, list) or len(case_ids) != len(expected_ids)
            or len(case_ids) != len(set(case_ids)) or set(case_ids) != expected_ids):
        raise ValueError("mcgill_chomp workload metadata does not match the pinned bounded game contract")
    readme = (ROOT / "benchmarks" / "c" / "mcgill_chomp" / "README.md").read_text(encoding="utf-8")
    if (source_url not in readme or launcher_url not in readme
            or "no explicit license grant" not in readme
            or "fixed at seven columns" not in readme):
        raise ValueError("mcgill_chomp README is missing its source, license, or bounded-board notes")
    for case in cases:
        input_value = case.get("input_value")
        expected = case.get("expected_result")
        if (set(case) != {"id", "input_value", "expected_result"}
                or type(input_value) is not int or not I64_MIN <= input_value <= I64_MAX
                or type(expected) is not int or expected != mcgill_chomp_expected(input_value)):
            raise ValueError(f"mcgill_chomp workload mismatch: {case.get('id')}")


AUTOMOTIVE_BITCOUNT_CASE_IDS = frozenset({
    "zero_iterations", "launcher_reference_profile", "negative_iterations",
    "above_launcher_bound", "signed_i64_minimum", "signed_i64_maximum",
})


def validate_automotive_bitcount_workload(workload: dict) -> None:
    source_files = [
        {"path": "MiBench/automotive-bitcount/bitarray.c", "blob_sha": "b21e8facccb8eb3d5f96bbb0878b89e0f8d87c15", "symbols": ["alloc_bit_array", "getbit", "setbit", "flipbit"]},
        {"path": "MiBench/automotive-bitcount/bitcnt_1.c", "blob_sha": "d41f57f1b348a4c9484c881495c9274a3e3f9fd2", "symbols": ["bit_count"]},
        {"path": "MiBench/automotive-bitcount/bitcnt_2.c", "blob_sha": "e34e119e32df6c04bdb910a9cdb0d7c3bb66a5f2", "symbols": ["bitcount"]},
        {"path": "MiBench/automotive-bitcount/bitcnt_3.c", "blob_sha": "9fe3025fdaaea83a5e5ed54f59a449435837b85f", "symbols": ["ntbl_bitcount", "BW_btbl_bitcount", "AR_btbl_bitcount"]},
        {"path": "MiBench/automotive-bitcount/bitcnt_4.c", "blob_sha": "9f76cd0f30a1a126e318ecb83d6899fd65d29f04", "symbols": ["ntbl_bitcnt", "btbl_bitcnt"]},
        {"path": "MiBench/automotive-bitcount/bitcnts.c", "blob_sha": "36fc7bc495034e718a92a69e4eedcf47d2356a37", "symbols": ["main", "bit_shifter"]},
        {"path": "MiBench/automotive-bitcount/bitfiles.c", "blob_sha": "504d4833f52a17c4a9b24345615e05eb98b139b9", "symbols": ["bfopen", "bfread", "bfwrite", "bfclose"]},
        {"path": "MiBench/automotive-bitcount/bitstrng.c", "blob_sha": "c9f326abb0e751da877553543dd5914f490cacef", "symbols": ["bitstring"]},
        {"path": "MiBench/automotive-bitcount/bstr_i.c", "blob_sha": "b4bfc733b1ab94a4500f3e3a70cbf63d4a896bf4", "symbols": ["bstr_i"]},
    ]
    pinned_source = {
        "repository": "lac-dcc/Benchmarks",
        "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
        "path": "MiBench/automotive-bitcount/bitcnts.c",
        "symbols": ["main", "bit_shifter", "bit_count", "bitcount", "ntbl_bitcnt", "ntbl_bitcount", "BW_btbl_bitcount", "AR_btbl_bitcount"],
        "files": source_files,
        "reference_output": {"path": "MiBench/automotive-bitcount/automotive-bitcount.reference_output", "blob_sha": "fef12507f13fd607ccb60f2431a979847a5058f1"},
        "source_license_file": {"path": "MiBench/automotive-bitcount/LICENSE", "blob_sha": "59bf08a00b01d8064c8be35deeb48571b4c43601"},
        "url": "https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-bitcount",
    }
    pinned_launcher = {
        "repository": "lac-dcc/Benchmarks",
        "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
        "path": "MiBench/automotive-bitcount/info.sh",
        "blob_sha": "78b6a90f1266925ee834faa8906eb4d40208b684",
        "bench_name": "automotive-bitcount",
        "source_files": ["bitarray.c", "bitcnt_1.c", "bitcnt_2.c", "bitcnt_3.c", "bitcnt_4.c", "bitcnts.c", "bitfiles.c", "bitstrng.c", "bstr_i.c"],
        "compile_flags": ["-lm"],
        "run_options": {"iterations": "1125000"},
        "url": "https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-bitcount/info.sh",
    }
    input_spec = {
        "kind": "signed_64_bit_integer",
        "meaning": "Number of generated values counted by each of the seven source algorithms.",
        "range": [0, AUTOMOTIVE_BITCOUNT_MAX_ITERATIONS],
        "invalid_input_result": -1,
    }
    output_spec = {
        "kind": "signed_64_bit_integer",
        "meaning": "Sum of the seven source-order bit totals weighted by their one-based algorithm positions.",
        "maximum_result": 1_008_000_000,
        "invalid_input_result": -1,
    }
    contract = {
        "source_algorithms": list(AUTOMOTIVE_BITCOUNT_ALGORITHM_NAMES),
        "source_seed_sequence": [16839, 18985, 21520, 3905, 10113, 8672, 21285],
        "seed_generation": "These are the first seven results of the pinned local rand() after srand(1); the source draws one start value per algorithm, then adds 13 before each subsequent value.",
        "counting": "Preserve the seven selected kernels: Kernighan bit clearing, parallel 32-bit bit summation, recursive nybble table, fixed eight-nybble table, BW four-byte table, AR four-byte table, and shift/test.",
        "result": "Each kernel accumulates its bit counts over the requested iteration count. Return the sum of each total multiplied by its one-based position in source order.",
        "bounded_profile": "Accept 0 through the launcher's 1125000 iterations. The generated seeds remain positive and below 2^31 throughout this profile.",
    }
    cases = workload.get("cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "lac-dcc-mibench-automotive-bitcount-bounded-scalar-v1"
            or workload.get("algorithm") != "automotive_bitcount"
            or workload.get("function_symbol") != "automotive_bitcount"
            or workload.get("pinned_source") != pinned_source
            or workload.get("pinned_launcher") != pinned_launcher
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("contract") != contract
            or workload.get("measurement") != {
                "comparison_model": "scalar_call",
                "sample_count": 3,
                "warmup_rounds": 0,
                "repetitions_per_sample": 1,
            }
            or not isinstance(cases, list)
            or len(case_ids) != len(AUTOMOTIVE_BITCOUNT_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != AUTOMOTIVE_BITCOUNT_CASE_IDS):
        raise ValueError("automotive_bitcount workload metadata does not match its pinned bounded scalar contract")
    readme = (ROOT / "benchmarks" / "a" / "automotive_bitcount" / "README.md").read_text(encoding="utf-8")
    source_url = "https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-bitcount"
    if source_url not in readme or "seven separate `Bits:` totals" not in readme or "count_set_bits" not in readme:
        raise ValueError("automotive_bitcount README is missing its pinned source or benchmark-level distinction")
    for case in cases:
        input_value = case.get("input_value")
        expected = case.get("expected_result")
        if (type(input_value) is not int or not I64_MIN <= input_value < (1 << 63)
                or type(expected) is not int or expected != automotive_bitcount_expected(input_value)):
            raise ValueError(f"automotive_bitcount workload mismatch: {case.get('id')}")
        totals = automotive_bitcount_checksums(input_value)
        checksums = case.get("algorithm_checksums")
        if totals is None:
            if checksums is not None:
                raise ValueError(f"automotive_bitcount invalid case must not include checksums: {case.get('id')}")
        elif (not isinstance(checksums, list)
                or any(type(value) is not int for value in checksums)
                or tuple(checksums) != totals):
            raise ValueError(f"automotive_bitcount source checksums mismatch: {case.get('id')}")
    if automotive_bitcount_checksums(AUTOMOTIVE_BITCOUNT_MAX_ITERATIONS) != AUTOMOTIVE_BITCOUNT_REFERENCE_CHECKSUMS:
        raise ValueError("automotive_bitcount oracle does not reproduce the pinned launcher reference checksums")


def validate_shootout_hash_workload(workload: dict) -> None:
    source_url = "https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/hash"
    source_files = [
        {"path": "Shootout/hash/hash.c", "blob_sha": "3ee3529e981fca431ce3c0584cdb1024d5e4a598", "symbols": ["main"]},
        {"path": "Shootout/hash/simple_hash.h", "blob_sha": "3ba7dd7e36d18b8a7eba881351f90134dcce7ff0", "symbols": ["ht_create", "ht_destroy", "ht_hashcode", "ht_find_new", "ht_find", "ht_node_create"]},
    ]
    expected_cases = {
        0: 0, 1: 1, 9: 9, 10: 9, 16: 10, 17: 11,
        SHOOTOUT_HASH_MAX_N: SHOOTOUT_HASH_REFERENCE_RESULT,
        -1: -1, SHOOTOUT_HASH_MAX_N + 1: -1,
        -(2**63): -1, 2**63 - 1: -1,
    }
    pinned_source = workload.get("pinned_source", {})
    launcher = workload.get("pinned_launcher", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "shootout_hash"
            or workload.get("function_symbol") != "shootout_hash"
            or pinned_source.get("repository") != "lac-dcc/Benchmarks"
            or pinned_source.get("commit") != "5d7b75df749241efa7a6e6f5be613d3fcc5cce38"
            or pinned_source.get("path") != "Shootout/hash/hash.c"
            or pinned_source.get("files") != source_files
            or pinned_source.get("url") != source_url
            or pinned_source.get("reference_output") != {
                "path": "Shootout/hash/hash.reference_output",
                "blob_sha": "d6bed147f9365a5322742006fd6da88ea1bfa26e",
            }
            or launcher.get("repository") != "lac-dcc/Benchmarks"
            or launcher.get("commit") != "5d7b75df749241efa7a6e6f5be613d3fcc5cce38"
            or launcher.get("path") != "Shootout/hash/info.sh"
            or launcher.get("blob_sha") != "7cf426f7ff349d279491d83657a086f530a008a3"
            or launcher.get("bench_name") != "hash"
            or launcher.get("source_files") != ["hash.c"]
            or launcher.get("compile_flags") != ["-lm"]
            or launcher.get("run_options") != ""
            or launcher.get("default_problem_size") != SHOOTOUT_HASH_MAX_N
            or launcher.get("small_problem_size_define_enabled") is not False
            or workload.get("input", {}).get("kind") != "signed_64_bit_integer"
            or workload.get("input", {}).get("range") != [0, SHOOTOUT_HASH_MAX_N]
            or workload.get("output", {}).get("kind") != "signed_64_bit_integer"
            or workload.get("measurement", {}).get("comparison_model") != "scalar_call"):
        raise ValueError("shootout_hash workload metadata does not match its pinned bounded scalar contract")
    readme = (ROOT / "benchmarks" / "s" / "shootout_hash" / "README.md").read_text(encoding="utf-8")
    if source_url not in readme or "3,500,000" not in readme or "6,291,469" not in readme:
        raise ValueError("shootout_hash README is missing its pinned source or launcher profile")
    cases = workload.get("cases")
    if not isinstance(cases, list) or len(cases) != len(expected_cases):
        raise ValueError("shootout_hash workload must include its complete bounded edge-case set")
    observed = set()
    for case in cases:
        input_value = case.get("input_value")
        if (type(input_value) is not int or input_value not in expected_cases
                or input_value in observed or type(case.get("expected_result")) is not int
                or case["expected_result"] != expected_cases[input_value]
                or case["expected_result"] != shootout_hash_expected(input_value)):
            raise ValueError(f"shootout_hash workload mismatch: {case.get('id')}")
        observed.add(input_value)
    if observed != set(expected_cases):
        raise ValueError("shootout_hash workload is missing required boundary cases")
    if shootout_hash_expected(SHOOTOUT_HASH_MAX_N) != SHOOTOUT_HASH_REFERENCE_RESULT:
        raise ValueError("shootout_hash oracle does not reproduce the pinned launcher reference output")


def validate_freebench_pifft_workload(workload: dict) -> None:
    pinned = "5d7b75df749241efa7a6e6f5be613d3fcc5cce38"
    source_url = f"https://github.com/lac-dcc/Benchmarks/tree/{pinned}/FreeBench/pifft"
    launcher_url = f"https://github.com/lac-dcc/Benchmarks/blob/{pinned}/FreeBench/pifft/info.sh"
    expected_cases = {"bounded_eight_point_profile", "profile_below_bound",
                      "profile_above_bound", "negative_length"}
    expected_source = {
        "repository": "lac-dcc/Benchmarks", "commit": pinned,
        "paths": ["FreeBench/pifft/pifft.c", "FreeBench/pifft/fftsg.c",
                  "FreeBench/pifft/info.sh", "FreeBench/pifft/test.in",
                  "FreeBench/pifft/ref.in", "FreeBench/pifft/pifft.reference_output"],
        "symbols": ["mp_mul", "mp_squ", "mp_inv", "mp_sqrt", "mp_sscanf",
                    "mp_sprintf", "main"],
        "url": source_url,
        "license_note": "The pifft.c header attributes the program to T. Ooura; neither pifft.c nor fftsg.c contains an explicit license grant, and the pinned directory has no separate license file. No upstream license is inferred. Ports and oracle are independently written from the modified AGM equations and observed behavior; no upstream source code or comments are copied.",
    }
    expected_launcher = {
        "repository": "lac-dcc/Benchmarks", "commit": pinned,
        "path": "FreeBench/pifft/info.sh", "bench_name": "pifft",
        "source_files": ["fftsg.c", "pifft.c"],
        "run_options": "test.in when SMALL_PROBLEM_SIZE is set; otherwise ref.in",
        "test_profile_nfft": 16384,
        "reference_profile_nfft": 1048576,
    }
    expected_contract = {
        "algorithm": "Modified Gauss-Legendre arithmetic-geometric mean recurrence from pifft.c, with an eight-point radix-2 FFT convolution used for fixed-point multiplication.",
        "input": "The only valid signed integer input is nfft=8, representing the bounded FFT length. Other values return -1.",
        "fixed_point_scale": 1000000,
        "multiplication": "Decompose each scaled operand into three base-1000 limbs, zero-pad their product to an 8-point radix-2 convolution, round coefficients to integers, reconstruct the exact limb product, then round to six decimal places.",
        "iteration": "Apply the source initialization and update order; stop when the residual is within one micro-unit or after eight updates.",
        "observable_result": "Round the modified AGM pi estimate half-up to milli-units; 3142 encodes 3.142.",
        "invalid_result": -1,
        "bounded_profile_note": "The source launcher selects nfft=16384 or 1048576. Those high-precision profiles are not reproduced; this workload fixes nfft=8 and reports a three-decimal result to keep the scalar ABI portable and bounded.",
    }
    cases = workload.get("cases")
    ids = ({case.get("id") for case in cases if isinstance(case, dict)}
           if isinstance(cases, list) else set())
    if (workload.get("schema_version") != 1
            or workload.get("id") != "lac-dcc-freebench-pifft-bounded-fft-agm-scalar-v1"
            or workload.get("algorithm") != "freebench_pifft"
            or workload.get("function_symbol") != "freebench_pifft"
            or workload.get("description") != "Bounded FFT-convolution multiplication within FreeBench's modified AGM pi calculation."
            or workload.get("pinned_source") != expected_source
            or workload.get("pinned_launcher") != expected_launcher
            or workload.get("contract") != expected_contract
            or workload.get("input") != {
                "kind": "signed_64_bit_integer", "meaning": "Fixed radix-2 transform length nfft.",
                "valid_value": FREEBENCH_PIFFT_FFT_SIZE, "invalid_input_result": -1,
            }
            or workload.get("output") != {
                "kind": "signed_64_bit_integer",
                "meaning": "Modified AGM estimate of pi rounded half-up to milli-units.",
                "scale": 1000, "valid_result": 3142, "invalid_input_result": -1,
            }
            or workload.get("measurement") != {
                "comparison_model": "scalar_call", "sample_count": 3,
                "warmup_rounds": 1, "repetitions_per_sample": 1,
            }
            or not isinstance(cases, list) or len(cases) != len(expected_cases)
            or len(ids) != len(cases) or ids != expected_cases):
        raise ValueError("freebench_pifft metadata or fixture IDs differ from its bounded contract")
    readme = (ROOT / "benchmarks" / "f" / "freebench_pifft" / "README.md").read_text(
        encoding="utf-8")
    if (source_url not in readme or launcher_url not in readme
            or "No upstream license is inferred" not in readme
            or "six fractional decimal places" not in readme or "nfft=8" not in readme):
        raise ValueError("freebench_pifft README is missing provenance, rights, or profile notes")
    observed: set[int] = set()
    for case in cases:
        input_value = case.get("input_value")
        if (set(case) != {"id", "input_value", "expected_result"}
                or type(input_value) is not int or not I64_MIN <= input_value <= I64_MAX
                or input_value in observed or type(case.get("expected_result")) is not int
                or case["expected_result"] != freebench_pifft_expected(input_value)):
            raise ValueError(f"freebench_pifft fixture differs from its oracle: {case.get('id')}")
        observed.add(input_value)
    if observed != {FREEBENCH_PIFFT_FFT_SIZE, 4, 16, -8}:
        raise ValueError("freebench_pifft workload is missing a bounded profile boundary case")


def validate_expected_result(algorithm: str, input_value: int, expected_result: int) -> None:
    if algorithm == "freebench_pifft":
        if expected_result != freebench_pifft_expected(input_value):
            raise ValueError("freebench_pifft expected_result must match the bounded fixed-point AGM oracle")
        return
    if algorithm == "fib2":
        if expected_result != fib2_expected(input_value):
            raise ValueError("fib2 expected_result must match the bounded recursive Shootout recurrence")
        return
    if algorithm == "nestedloop":
        if expected_result != nestedloop_expected(input_value):
            raise ValueError("nestedloop expected_result must match the bounded six-loop count")
        return
    if algorithm == "mcgill_chomp":
        if expected_result != mcgill_chomp_expected(input_value):
            raise ValueError("mcgill_chomp expected_result must match the bounded Chomp game-tree outcome")
        return
    if algorithm == "automotive_bitcount":
        if expected_result != automotive_bitcount_expected(input_value):
            raise ValueError("automotive_bitcount expected_result must match the weighted seven-kernel checksum")
        return
    if algorithm == "shootout_hash":
        if expected_result != shootout_hash_expected(input_value):
            raise ValueError("shootout_hash expected_result must match the bounded decimal lookup count")
        return
    if algorithm == "greatest_prime_factor":
        if expected_result != greatest_prime_factor_expected(input_value):
            raise ValueError("greatest_prime_factor expected_result must match the bounded factorization oracle")
        return
    if algorithm == "multiple_of_3_or_5_term":
        if expected_result != multiple_of_3_or_5_term_expected(input_value):
            raise ValueError("multiple_of_3_or_5_term expected_result must match the one-term divisibility filter")
        return
    if algorithm == "so1":
        if expected_result != so1_expected(input_value):
            raise ValueError("so1 expected_result must match the bounded even-Fibonacci sum")
        return
    if algorithm == "magic_square":
        if expected_result != magic_square_expected(input_value):
            raise ValueError("magic_square expected_result must match the bounded Siamese-square hash")
        return
    if algorithm == "trial_division_factorizer":
        expected_from_source = trial_division_factorizer_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("trial_division_factorizer expected_result must match the bounded smallest-factor search")
        return
    if algorithm == "pollards_rho_factorizing":
        if expected_result != pollards_rho_factorizing_expected(input_value):
            raise ValueError("pollards_rho_factorizing expected_result must preserve the first non-one gcd")
        return
    if algorithm == "mersenne_primes":
        expected_from_source = mersenne_primes_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("mersenne_primes expected_result must match the bounded Mersenne-prime predicate")
        return
    if algorithm == "binary_palindrome_check":
        if not -(2**31) <= input_value <= 2**31 - 1:
            expected_from_source = -1
        elif input_value < 0:
            expected_from_source = 0
        else:
            bits = bin(input_value)[2:]
            expected_from_source = int(bits == bits[::-1])
        if expected_result != expected_from_source:
            raise ValueError("binary_palindrome_check expected_result must match significant-bit reversal")
        return
    if algorithm == "sum_multiples_inclusion_exclusion":
        if expected_result != sum_multiples_inclusion_exclusion_expected(input_value):
            raise ValueError("sum_multiples_inclusion_exclusion expected_result must match the direct-scan oracle")
        return
    if algorithm == "problem12_sol1":
        expected_from_source = 76_576_500 if input_value == 500 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem12_sol1 expected_result must match the fixed 500-divisor threshold search")
        return
    if algorithm == "problem014":
        expected_from_source = (problem014_expected(input_value)
                                if 1 <= input_value <= PROBLEM014_MAX_LIMIT else -1)
        if expected_result != expected_from_source:
            raise ValueError("problem014 expected_result must match the source-pinned exclusive Collatz limit oracle")
        return
    if algorithm == "twos_complement_of_binary":
        expected_from_source = twos_complement_of_binary_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("twos_complement_of_binary expected_result must match the bounded binary-digit complement")
        return
    if algorithm == "liouville":
        expected_from_source = liouville_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("liouville expected_result must match distinct-prime-factor parity")
        return
    if algorithm == "gauss_easter":
        expected_from_source = gauss_easter_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("gauss_easter expected_result must preserve the pinned UTC Easter date")
        return
    if algorithm == "leap_year":
        expected_from_source = leap_year_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("leap_year expected_result must match the positive Gregorian divisibility rule")
        return
    if algorithm == "is_odd":
        expected_from_source = is_odd_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("is_odd expected_result must match signed remainder parity")
        return
    if algorithm == "binary_length":
        expected_from_source = binary_length_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("binary_length expected_result must match bounded positive-integer bit length")
        return
    if algorithm == "all_ones_sequence":
        expected_from_source = all_ones_sequence_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("all_ones_sequence expected_result must match the indexed constant-one sequence")
        return
    if algorithm == "all_twos_sequence":
        expected_from_source = all_twos_sequence_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("all_twos_sequence expected_result must match the indexed constant-two sequence")
        return
    if algorithm == "all_threes_sequence":
        expected_from_source = all_threes_sequence_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("all_threes_sequence expected_result must match the indexed constant-three sequence")
        return
    if algorithm == "cubes_sequence":
        expected_from_source = cubes_sequence_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("cubes_sequence expected_result must match the bounded zero-based cube")
        return
    if algorithm == "count_set_bits":
        expected_from_source = count_set_bits_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("count_set_bits expected_result must match the bounded prefix popcount")
        return
    if algorithm == "count_leading_zeros":
        expected_from_source = count_leading_zeros_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("count_leading_zeros expected_result must match the fixed-width int32 count")
        return
    if algorithm == "clear_leftmost_set_bit":
        expected_from_source = clear_leftmost_set_bit_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("clear_leftmost_set_bit expected_result must clear the highest set bit")
        return
    if algorithm == "clear_lowest_set_bit":
        expected_from_source = clear_lowest_set_bit_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("clear_lowest_set_bit expected_result must clear the lowest set bit")
        return
    if algorithm == "sum_of_odd_numbers":
        expected_from_source = sum_of_odd_numbers_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("sum_of_odd_numbers expected_result must match the bounded square identity")
        return
    if algorithm == "carmichael_number":
        expected_from_source = carmichael_number_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("carmichael_number expected_result must match Korselt's criterion")
        return
    if algorithm == "evil_number":
        expected_from_source = evil_number_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("evil_number expected_result must match signed-64-bit popcount parity")
        return
    if algorithm == "keith_number":
        expected_from_source = keith_number_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("keith_number expected_result must match the digit-seeded recurrence")
        return
    if algorithm == "kynea_numbers":
        expected_from_source = kynea_numbers_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("kynea_numbers expected_result must match the bounded one-based formula")
        return
    if algorithm == "padovan_sequence":
        expected_from_source = padovan_sequence_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("padovan_sequence expected_result must match the bounded recurrence")
        return
    if algorithm == "pell_number":
        expected_from_source = pell_number_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("pell_number expected_result must match the bounded Pell recurrence")
        return
    if algorithm == "perrin_number":
        expected_from_source = perrin_number_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("perrin_number expected_result must match the bounded Perrin recurrence")
        return
    if algorithm == "smith_number":
        expected_from_source = smith_number_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("smith_number expected_result must match the composite factor digit sum")
        return
    if algorithm == "sphenic_number":
        expected_from_source = sphenic_number_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("sphenic_number expected_result must have exactly three distinct prime factors")
        return
    if algorithm == "liouville_lambda":
        expected_from_source = -1
        if 1 <= input_value <= 2_147_483_647:
            remaining, parity, factor = input_value, 0, 2
            while factor <= remaining // factor:
                while remaining % factor == 0:
                    remaining //= factor
                    parity ^= 1
                factor += 1
            if remaining > 1:
                parity ^= 1
            expected_from_source = -1 if parity else 1
        if expected_result != expected_from_source:
            raise ValueError("liouville_lambda expected_result must match prime-factor multiplicity parity")
        return
    if algorithm == "euler_totient":
        expected_from_source = -1
        if 1 <= input_value <= 1_000_000:
            remaining = input_value
            expected_from_source = input_value
            factor = 2
            while factor * factor <= remaining:
                if remaining % factor == 0:
                    expected_from_source -= expected_from_source // factor
                    while remaining % factor == 0:
                        remaining //= factor
                factor += 1
            if remaining > 1:
                expected_from_source -= expected_from_source // remaining
        if expected_result != expected_from_source:
            raise ValueError("euler_totient expected_result must match prime-factor Euler phi on the bounded domain")
        return
    if algorithm == "problem111":
        expected_from_source = problem111_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem111 expected_result must match the pinned candidate generation and divisibility scan")
        return
    if algorithm == "problem122":
        expected_from_source = problem122_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem122 expected_result must match source-ordered star addition-chain search")
        return
    if algorithm == "problem123":
        expected_from_source = problem123_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem123 expected_result must match the source prime-remainder scan")
        return
    if algorithm == "problem109":
        expected_from_source = problem109_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem109 expected_result must match the source checkout enumeration")
        return
    if algorithm == "problem117":
        expected_from_source = problem117_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem117 expected_result must match the source tile-placement recurrence")
        return
    if algorithm == "problem119":
        expected_from_source = problem119_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem119 expected_result must match the bounded digit-power multiset")
        return
    if algorithm == "problem120":
        expected_from_source = problem120_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem120 expected_result must match the inclusive square-remainder sum")
        return
    if algorithm == "problem129":
        expected_from_source = problem129_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem129 expected_result must match the source repunit-length search")
        return
    if algorithm == "problem135":
        expected_from_source = problem135_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem135 expected_result must match the bounded source divisor scan")
        return
    if algorithm == "problem136":
        expected_from_source = problem136_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem136 expected_result must match the source delta/y traversal")
        return
    if algorithm == "problem137":
        expected_from_source = problem137_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem137 expected_result must match the bounded Fibonacci product")
        return
    if algorithm == "problem138":
        expected_from_source = problem138_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem138 expected_result must match the Pell pair recurrence")
        return
    if algorithm == "problem142":
        expected_from_source = problem142_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem142 expected_result must match the bounded perfect-square search")
        return
    if algorithm == "problem145":
        expected_from_source = problem145_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem145 expected_result must match the carry-based reversible count")
        return
    if algorithm == "problem164":
        expected_from_source = problem164_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem164 expected_result must match the digit-sum recursion")
        return
    if algorithm == "problem173":
        expected_from_source = problem173_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem173 expected_result must match the lamina width scan")
        return
    if algorithm == "problem190":
        expected_from_source = problem190_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem190 expected_result must match the bounded binary64 product scan")
        return
    if algorithm == "problem551":
        expected_from_source = problem551_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem551 expected_result must match the source digit-sum jump sequence")
        return
    if algorithm == "problem493":
        expected_from_source = problem493_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem493 expected_result must match the pinned expectation formatting")
        return
    if algorithm == "problem206":
        expected_from_source = problem206_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem206 expected_result must match the pinned concealed-square search")
        return
    if algorithm == "problem191":
        expected_from_source = problem191_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem191 expected_result must match the pinned attendance-state recursion")
        return
    if algorithm == "problem187":
        expected_from_source = problem187_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem187 expected_result must match the strict-cutoff prime pair scan")
        return
    if algorithm == "problem180":
        expected_from_source = problem180_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem180 expected_result must match the pinned rational golden-triple scan")
        return
    if algorithm == "problem203":
        expected_from_source = problem203_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem203 expected_result must match the Pascal coefficient squarefree scan")
        return
    if algorithm == "problem205":
        expected_from_source = problem205_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem205 expected_result must match the pinned dice probability rounding")
        return
    if algorithm == "problem234":
        expected_from_source = problem234_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem234 expected_result must match the adjacent-prime-square scan")
        return
    if algorithm == "problem301":
        expected_from_source = problem301_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem301 expected_result must match the pinned Binet conversion")
        return
    if algorithm == "problem401":
        expected_from_source = problem401_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem401 expected_result must match the divisor-list accumulation")
        return
    if algorithm == "problem686":
        expected_from_source = problem686_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem686 expected_result must match the rounded logarithm interval scan")
        return
    if algorithm == "problem125":
        expected_from_source = problem125_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem125 expected_result must match distinct consecutive-square palindromes")
        return
    if algorithm == "problem131":
        expected_from_source = problem131_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem131 expected_result must match the source prime-candidate scan")
        return
    if algorithm == "problem121":
        expected_from_source = problem121_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem121 expected_result must match exact source probability weights")
        return
    if algorithm == "problem104":
        expected_from_source = problem104_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem104 expected_result must match the bounded Fibonacci search")
        return
    if algorithm == "problem114":
        expected_from_source = problem114_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem114 expected_result must match the source block-placement recurrence")
        return
    if algorithm == "problem116":
        expected_from_source = problem116_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem116 expected_result must match the source tile-placement recurrence")
        return
    if algorithm == "problem115":
        if not 1 <= input_value <= 100:
            expected_from_source = -1
        else:
            ways = [0] * 1024
            for length in range(input_value):
                ways[length] = 1
            expected_from_source = -1
            for n in range(input_value, len(ways)):
                ways[n] = 1
                for block_length in range(input_value, n + 1):
                    for block_start in range(n - block_length):
                        ways[n] += ways[n - block_start - block_length - 1]
                    ways[n] += 1
                if ways[n] > 1_000_000:
                    expected_from_source = n
                    break
        if expected_result != expected_from_source:
            raise ValueError("problem115 expected_result must match the source block-placement recurrence")
        return
    if algorithm == "problem112":
        if not 1 <= input_value <= 99:
            expected_from_source = -1
        else:
            bouncy_count = 0
            expected_from_source = -1
            for number in range(1, 2_000_001):
                digits = str(number)
                nondecreasing = all(left <= right for left, right in zip(digits, digits[1:]))
                nonincreasing = all(left >= right for left, right in zip(digits, digits[1:]))
                bouncy_count += not (nondecreasing or nonincreasing)
                if bouncy_count * 100 >= input_value * number:
                    expected_from_source = number
                    break
        if expected_result != expected_from_source:
            raise ValueError("problem112 expected_result must be the first exact integer-percentage crossing")
        return
    if algorithm == "problem113":
        if input_value > 100:
            expected_from_source = -1
        else:
            expected_from_source = sum(math.comb(8 + digits, digits)
                                       + math.comb(9 + digits, digits) - 10
                                       for digits in range(1, max(0, input_value) + 1))
        if expected_result != expected_from_source:
            raise ValueError("problem113 expected_result must sum the bounded non-bouncy count formula")
        return
    if algorithm == "problem100":
        if not 0 <= input_value <= 1_000_000_000_000:
            expected_from_source = -1
        else:
            previous_numerator, previous_denominator = 1, 0
            numerator, denominator = 1, 1
            while numerator <= 2 * input_value - 1:
                previous_numerator += 2 * numerator
                numerator += 2 * previous_numerator
                previous_denominator += 2 * denominator
                denominator += 2 * previous_denominator
            expected_from_source = (denominator + 1) // 2
        if expected_result != expected_from_source:
            raise ValueError("problem100 expected_result must match the source blue-disc recurrence")
        return
    if algorithm == "problem101":
        if input_value > 10:
            expected_from_source = -1
        else:
            def sequence_term(position: int) -> int:
                return sum((-1) ** power * position ** power for power in range(11))

            expected_from_source = 0
            for order in range(1, max(0, input_value) + 1):
                x = order + 1
                predicted = Fraction(0)
                for point in range(1, order + 1):
                    term = Fraction(sequence_term(point))
                    for other in range(1, order + 1):
                        if other != point:
                            term *= Fraction(x - other, point - other)
                    predicted += term
                expected_from_source += int(predicted)
        if expected_result != expected_from_source:
            raise ValueError("problem101 expected_result must sum the first exact Lagrange fit errors")
        return
    if algorithm == "problem95":
        expected_from_source = problem95_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem95 expected_result must preserve the bounded chain traversal and strict tie behavior")
        return
    if algorithm == "problem94":
        if not 0 <= input_value <= 1_000_000_000:
            expected_from_source = -1
        else:
            previous, value, total, index, perimeter = 1, 2, 0, 0, 0
            while perimeter <= input_value:
                total += perimeter
                previous += 2 * value
                value += previous
                perimeter = 2 * value + 2 if index % 2 == 0 else 2 * value - 2
                index += 1
            expected_from_source = total
        if expected_result != expected_from_source:
            raise ValueError("problem94 expected_result must match the source Pell recurrence and perimeter bound")
        return
    if algorithm == "problem97":
        if not 0 <= input_value <= 18:
            expected_from_source = -1
        else:
            modulus = 10 ** input_value
            expected_from_source = (28433 * pow(2, 7_830_457, modulus) + 1) % modulus
        if expected_result != expected_from_source:
            raise ValueError("problem97 expected_result must match the executable modular suffix expression")
        return
    if algorithm == "problem92":
        if not 0 <= input_value <= 10_000_000:
            expected_from_source = -1
        else:
            digits = list(map(int, str(input_value)))
            loose = {0: 1}
            tight_sum = 0
            for bound_digit in digits:
                next_loose: dict[int, int] = {}
                for subtotal, ways in loose.items():
                    for digit in range(10):
                        new_sum = subtotal + digit * digit
                        next_loose[new_sum] = next_loose.get(new_sum, 0) + ways
                for digit in range(bound_digit):
                    new_sum = tight_sum + digit * digit
                    next_loose[new_sum] = next_loose.get(new_sum, 0) + 1
                loose = next_loose
                tight_sum += bound_digit * bound_digit
            # `loose` counts all nonnegative values below input_value.
            expected_from_source = 0
            for digit_sum, ways in loose.items():
                if digit_sum == 0:
                    continue
                endpoint = digit_sum
                while endpoint not in (1, 89):
                    endpoint = sum(int(character) ** 2 for character in str(endpoint))
                if endpoint == 89:
                    expected_from_source += ways
        if expected_result != expected_from_source:
            raise ValueError("problem92 expected_result must count positive square-digit chains below the exclusive limit")
        return
    if algorithm == "problem89":
        if input_value != 0:
            expected_from_source = -1
        else:
            numeral_values = {"I": 1, "V": 5, "X": 10, "L": 50,
                              "C": 100, "D": 500, "M": 1000}
            minimal_tokens = ((1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
                              (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
                              (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"))
            saved = 0
            for numeral in (ROOT / "benchmarks/p/problem89/roman.txt").read_text(encoding="ascii").splitlines():
                value = 0
                for index, symbol in enumerate(numeral):
                    amount = numeral_values[symbol]
                    value += -amount if index + 1 < len(numeral) and amount < numeral_values[numeral[index + 1]] else amount
                remaining, minimal_length = value, 0
                for amount, token in minimal_tokens:
                    count, remaining = divmod(remaining, amount)
                    minimal_length += count * len(token)
                saved += len(numeral) - minimal_length
            expected_from_source = saved
        if expected_result != expected_from_source:
            raise ValueError("problem89 expected_result must match fixed Roman dataset character savings")
        return
    if algorithm == "problem91":
        if not 0 <= input_value <= 50:
            expected_from_source = -1
        else:
            points = [(x, y) for x in range(input_value + 1)
                      for y in range(input_value + 1) if x != 0 or y != 0]
            expected_from_source = 0
            for (x1, y1), (x2, y2) in combinations(points, 2):
                origin_first = x1 * x1 + y1 * y1
                origin_second = x2 * x2 + y2 * y2
                between = (x1 - x2) ** 2 + (y1 - y2) ** 2
                if (origin_first + origin_second == between
                        or origin_first + between == origin_second
                        or origin_second + between == origin_first):
                    expected_from_source += 1
        if expected_result != expected_from_source:
            raise ValueError("problem91 expected_result must count source-enumerated unordered right triangles")
        return
    if algorithm == "problem87":
        expected_from_source = problem87_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem87 expected_result must count distinct prime power sums below limit")
        return
    if algorithm == "problem85":
        if not 0 <= input_value <= 2_000_000_000:
            expected_from_source = -1
        else:
            bound = math.ceil(math.sqrt(2 * input_value) * 1.1)
            best_product, area = 0, 0
            for a in range(1, bound):
                triangle_a = a * (a + 1) // 2
                estimate = (-1.0 + math.sqrt(1.0 + 8.0 * input_value / triangle_a)) / 2.0
                floor_b, ceil_b = math.floor(estimate), math.ceil(estimate)
                floor_product = triangle_a * floor_b * (floor_b + 1) // 2
                ceil_product = triangle_a * ceil_b * (ceil_b + 1) // 2
                if abs(input_value - floor_product) < abs(input_value - best_product):
                    best_product, area = floor_product, a * floor_b
                if abs(input_value - ceil_product) < abs(input_value - best_product):
                    best_product, area = ceil_product, a * ceil_b
            expected_from_source = area
        if expected_result != expected_from_source:
            raise ValueError("problem85 expected_result must preserve the source bound, candidate order, and strict ties")
        return
    if algorithm == "problem86":
        if input_value > 1_000_000:
            expected_from_source = -1
        elif input_value < 0:
            expected_from_source = 0
        else:
            total, side, expected_from_source = 0, 0, -1
            while total <= input_value:
                side += 1
                for combined in range(2, 2 * side + 1):
                    path_squared = combined * combined + side * side
                    path = math.isqrt(path_squared)
                    if path * path == path_squared:
                        total += min(side, combined // 2) + 1 - max(1, combined - side)
            expected_from_source = side
        if expected_result != expected_from_source:
            raise ValueError("problem86 expected_result must match the complete cuboid side-layer search")
        return
    if algorithm == "problem79":
        expected_from_source = 73162890 if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem79 returns the fixed keylog passcode only for placeholder zero")
        return
    if algorithm == "problem80":
        expected_from_source = 40886 if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem80 expected_result must match the fixed 105-digit Decimal square-root calculation")
        return
    if algorithm == "problem78":
        if not 1 <= input_value <= 1_000_000:
            expected_from_source = -1
        else:
            partitions = [1]
            expected_from_source = -1
            for n in range(1, 55_375):
                residue = 0
                index = 1
                while True:
                    lower = index * (3 * index - 1) // 2
                    if lower > n:
                        break
                    sign = 1 if index % 2 == 1 else -1
                    residue = (residue + sign * partitions[n - lower]) % input_value
                    upper = index * (3 * index + 1) // 2
                    if upper <= n:
                        residue = (residue + sign * partitions[n - upper]) % input_value
                    index += 1
                if residue == 0:
                    expected_from_source = n
                    break
                partitions.append(residue)
        if expected_result != expected_from_source:
            raise ValueError("problem78 expected_result must match the bounded generalized-pentagonal search")
        return
    if algorithm == "problem70":
        if not 0 <= input_value <= 10_000_000:
            expected_from_source = -1
        else:
            # Model the pinned full totient sieve and ascending strict-ratio scan.
            phi = array("I", range(input_value + 1))
            for prime in range(2, input_value + 1):
                if phi[prime] == prime:
                    for multiple in range(prime, input_value + 1, prime):
                        phi[multiple] -= phi[multiple] // prime
            best, best_phi = 0, 1
            for number in range(2, input_value + 1):
                value = phi[number]
                improves = best == 0 or number * best_phi < best * value
                if improves and sorted(str(number)) == sorted(str(value)):
                    best, best_phi = number, value
            expected_from_source = best or 1
        if expected_result != expected_from_source:
            raise ValueError("problem70 expected_result must match the ascending totient-permutation search")
        return
    if algorithm == "problem76":
        if not 1 <= input_value <= 200:
            expected_from_source = -1
        else:
            # Preserve the source's (m+1) by m recurrence and final subtraction.
            memo = [[0] * input_value for _ in range(input_value + 1)]
            for n in range(input_value + 1):
                memo[n][0] = 1
            for n in range(input_value + 1):
                for k in range(1, input_value):
                    memo[n][k] = memo[n][k - 1]
                    if n > k:
                        memo[n][k] += memo[n - k - 1][k]
            expected_from_source = memo[input_value][input_value - 1] - 1
        if expected_result != expected_from_source:
            raise ValueError("problem76 expected_result must match the source partition table")
        return
    if algorithm == "problem75":
        if input_value > 1_500_000:
            expected_from_source = -1
        else:
            frequencies = bytearray(max(0, input_value) + 1)
            m = 2
            while 2 * m * (m + 1) <= input_value:
                for n in range((m % 2) + 1, m, 2):
                    if math.gcd(m, n) != 1:
                        continue
                    perimeter = 2 * m * (m + n)
                    for multiple in range(perimeter, input_value + 1, perimeter):
                        if frequencies[multiple] < 2:
                            frequencies[multiple] += 1
                m += 1
            expected_from_source = frequencies.count(1)
        if expected_result != expected_from_source:
            raise ValueError("problem75 expected_result must match the primitive-triple perimeter scan")
        return
    if algorithm == "problem77":
        if not 0 <= input_value <= 100_000:
            expected_from_source = -1
        else:
            partitions = [0] * 100
            partitions[0] = 1
            for prime in range(2, 100):
                if any(prime % divisor == 0 for divisor in range(2, math.isqrt(prime) + 1)):
                    continue
                for total in range(prime, 100):
                    partitions[total] += partitions[total - prime]
            expected_from_source = next(
                (value for value in range(1, 100) if partitions[value] > input_value), -1)
        if expected_result != expected_from_source:
            raise ValueError("problem77 expected_result must match the first bounded prime-partition threshold crossing")
        return
    if algorithm == "problem72":
        if not 0 <= input_value <= 1_000_000:
            expected_from_source = -1
        else:
            # Match the pinned NumPy initialization and update order exactly.
            phi = list(range(-1, input_value))
            for value in range(2, input_value + 1):
                if phi[value] == value - 1:
                    for multiple in range(2 * value, input_value + 1, value):
                        phi[multiple] -= phi[multiple] // value
            expected_from_source = sum(phi[2:input_value + 1])
        if expected_result != expected_from_source:
            raise ValueError("problem72 expected_result must match the inclusive totient sum through limit")
        return
    if algorithm == "problem73":
        if not 0 <= input_value <= 12_000:
            expected_from_source = -1
        else:
            expected_from_source = 0
            for denominator in range(2, input_value + 1):
                numerator = denominator // 3 + 1
                end = (denominator + 1) // 2
                if denominator % 2 == 0 and numerator % 2 == 0:
                    numerator += 1
                step = 2 if denominator % 2 == 0 else 1
                for candidate in range(numerator, end, step):
                    if math.gcd(candidate, denominator) == 1:
                        expected_from_source += 1
        if expected_result != expected_from_source:
            raise ValueError("problem73 expected_result must match the source denominator scan")
        return
    if algorithm == "sum_of_divisors":
        if not 1 <= input_value <= 1_000_000:
            expected_from_source = -1
        else:
            expected_from_source = 0
            divisor = 1
            while divisor <= input_value // divisor:
                if input_value % divisor == 0:
                    partner = input_value // divisor
                    expected_from_source += divisor
                    if partner != divisor:
                        expected_from_source += partner
                divisor += 1
        if expected_result != expected_from_source:
            raise ValueError("sum_of_divisors expected_result must match the bounded positive-divisor sum")
        return
    if algorithm == "abundant_number":
        if not 1 <= input_value <= 100_000_000:
            expected_from_source = -1
        else:
            proper_divisor_sum = 1
            divisor = 2
            while divisor <= input_value // divisor:
                if input_value % divisor == 0:
                    proper_divisor_sum += divisor
                    partner = input_value // divisor
                    if partner != divisor:
                        proper_divisor_sum += partner
                    if proper_divisor_sum > input_value:
                        break
                divisor += 1
            expected_from_source = int(proper_divisor_sum > input_value)
        if expected_result != expected_from_source:
            raise ValueError("abundant_number expected_result must match the bounded proper-divisor predicate")
        return
    if algorithm == "pi_generator":
        expected_from_source = pi_generator_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("pi_generator expected_result must hash the pinned spigot decimal string")
        return
    if algorithm == "pascal_triangle_ii":
        expected_from_source = pascal_triangle_ii_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("pascal_triangle_ii expected_result must hash the pinned zero-based Pascal row")
        return
    if algorithm == "partitions":
        expected_from_source = partitions_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("partitions expected_result must match the bounded Julia recursive partition count")
        return
    if algorithm == "integer_partition":
        if not 1 <= input_value <= 300:
            expected_from_source = I64_MIN
        else:
            partitions = [0] * (input_value + 1)
            partitions[0] = 1
            for part in range(1, input_value + 1):
                for total in range(part, input_value + 1):
                    partitions[total] += partitions[total - part]
            expected_from_source = partitions[input_value]
        if expected_result != expected_from_source:
            raise ValueError("integer_partition expected_result must match the bounded unordered partition count")
        return
    if algorithm == "mobius_function":
        if not 1 <= input_value <= 10_000:
            expected_from_source = I64_MIN
        else:
            remaining = input_value
            distinct_prime_factors = 0
            factor = 2
            square_factor = False
            while factor * factor <= remaining:
                if remaining % factor == 0:
                    remaining //= factor
                    if remaining % factor == 0:
                        square_factor = True
                        break
                    distinct_prime_factors += 1
                    while remaining % factor == 0:
                        remaining //= factor
                factor = 3 if factor == 2 else factor + 2
            if square_factor:
                expected_from_source = 0
            else:
                if remaining > 1:
                    distinct_prime_factors += 1
                expected_from_source = 1 if distinct_prime_factors % 2 == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("mobius_function expected_result must match the bounded distinct-prime Möbius value")
        return
    if algorithm == "fibonacci_recursive":
        if 0 <= input_value <= 30:
            previous, current = 0, 1
            for _ in range(input_value):
                previous, current = current, previous + current
            expected_from_source = previous
        else:
            expected_from_source = -1
        if expected_result != expected_from_source:
            raise ValueError("fibonacci_recursive expected_result must match the bounded Fibonacci recurrence")
        return
    if algorithm == "prime_check_naive":
        if input_value < 2:
            expected_from_source = 0
        elif input_value > 10_000:
            expected_from_source = -1
        else:
            expected_from_source = int(all(input_value % divisor != 0
                                           for divisor in range(2, input_value)))
        if expected_result != expected_from_source:
            raise ValueError("prime_check_naive expected_result must match bounded plain trial division")
        return
    if algorithm == "reverse_number":
        if not 0 <= input_value <= 1_000_000_000:
            expected_from_source = -1
        else:
            source_input = input_value
            expected_from_source = 0
            while source_input:
                expected_from_source = expected_from_source * 10 + source_input % 10
                source_input //= 10
        if expected_result != expected_from_source:
            raise ValueError("reverse_number expected_result must match repeated decimal digit reversal")
        return
    if algorithm == "hardy_ramanujanalgo":
        if not 1 <= input_value <= 2_147_483_647:
            expected_from_source = -1
        else:
            remaining = input_value
            distinct_factors = 0
            divisor = 2
            while divisor * divisor <= remaining:
                if remaining % divisor == 0:
                    distinct_factors += 1
                    while remaining % divisor == 0:
                        remaining //= divisor
                divisor = 3 if divisor == 2 else divisor + 2
            if remaining > 1:
                distinct_factors += 1
            expected_from_source = distinct_factors
        if expected_result != expected_from_source:
            raise ValueError("hardy_ramanujanalgo expected_result must match exact distinct-prime-factor counting")
        return
    if algorithm == "fast_factorial":
        expected_from_source = math.factorial(input_value) if 0 <= input_value <= 20 else -1
        if expected_result != expected_from_source:
            raise ValueError("fast_factorial expected_result must match the exact factorial on 0..20")
        return
    if algorithm == "alaw":
        if not -32768 <= input_value <= 32767:
            expected_from_source = -1
        else:
            sign = 0x80 if input_value < 0 else 0
            magnitude = -input_value - 1 if input_value < 0 else input_value
            segment, mask = 7, 0x4000
            while (magnitude & mask) == 0 and segment > 0:
                segment -= 1
                mask >>= 1
            shift = segment + 3 if segment != 0 else 4
            quantization = (magnitude >> shift) & 0x0F
            expected_from_source = (sign | (segment << 4) | quantization) ^ 0xD5
        if expected_result != expected_from_source:
            raise ValueError("alaw expected_result must match the bounded A-law encoder")
        return
    if algorithm == "alaw_decode":
        if not 0 <= input_value <= 255:
            expected_from_source = -1
        else:
            codeword = input_value ^ 0xD5
            magnitude = ((codeword & 0x0F) << 4) | 8
            segment = (codeword & 0x70) >> 4
            if segment != 0:
                magnitude += 0x100
            shift = segment - 1 if segment > 1 else 0
            magnitude <<= shift
            expected_from_source = -magnitude if codeword & 0x80 else magnitude
        if expected_result != expected_from_source:
            raise ValueError("alaw_decode expected_result must match the bounded A-law decoder")
        return
    if algorithm == "parity_check":
        if not -(2**31) <= input_value <= 2**31 - 1:
            expected_from_source = -1
        elif input_value < 0:
            expected_from_source = 1
        else:
            expected_from_source = int(input_value.bit_count() % 2 == 0)
        if expected_result != expected_from_source:
            raise ValueError("parity_check expected_result must match the pinned positive-only bit loop")
        return
    if algorithm == "minimum_steps_to_one":
        if not 1 <= input_value <= 10_000:
            expected_from_source = -1
        else:
            table = [input_value + 1] * (input_value + 1)
            table[1] = 0
            for index in range(1, input_value):
                next_value = index + 1
                table[next_value] = min(table[next_value], table[index] + 1)
                if index * 2 <= input_value:
                    table[index * 2] = min(table[index * 2], table[index] + 1)
                if index * 3 <= input_value:
                    table[index * 3] = min(table[index * 3], table[index] + 1)
            expected_from_source = table[input_value]
        if expected_result != expected_from_source:
            raise ValueError("minimum_steps_to_one expected_result must match pinned forward tabulation")
        return
    if algorithm == "problem1":
        if not 0 <= input_value <= 100_000:
            expected_from_source = -1
        else:
            expected_from_source = sum(
                value for value in range(1, input_value)
                if value % 3 == 0 or value % 5 == 0
            )
        if expected_result != expected_from_source:
            raise ValueError("problem1 expected_result must match the bounded sum of multiples below the limit")
        return
    if algorithm == "problem2":
        if not 0 <= input_value <= 4_000_000:
            expected_from_source = -1
        else:
            previous, current = 1, 2
            expected_from_source = 0
            while current < input_value:
                if current % 2 == 0:
                    expected_from_source += current
                previous, current = current, previous + current
        if expected_result != expected_from_source:
            raise ValueError("problem2 expected_result must match the bounded even-Fibonacci sum")
        return
    if algorithm == "problem3":
        if not 2 <= input_value <= 600_851_475_143:
            expected_from_source = -1
        else:
            remaining = input_value
            largest_factor = 1
            divisor = 2
            while divisor <= remaining // divisor:
                while remaining % divisor == 0:
                    largest_factor = divisor
                    remaining //= divisor
                divisor = 3 if divisor == 2 else divisor + 2
            if remaining > 1:
                largest_factor = remaining
            expected_from_source = largest_factor
        if expected_result != expected_from_source:
            raise ValueError("problem3 expected_result must match the bounded largest-prime-factor calculation")
        return
    if algorithm == "problem4":
        if not 1 <= input_value <= 3:
            expected_from_source = -1
        else:
            lower = 10 ** (input_value - 1)
            upper = 10 ** input_value - 1
            largest_palindrome = 0
            for first in range(upper, lower - 1, -1):
                if first * upper <= largest_palindrome:
                    break
                for second in range(first, lower - 1, -1):
                    product = first * second
                    if product <= largest_palindrome:
                        break
                    digits = str(product)
                    if digits == digits[::-1]:
                        largest_palindrome = product
                        break
            expected_from_source = largest_palindrome
        if expected_result != expected_from_source:
            raise ValueError("problem4 expected_result must match the bounded largest palindrome product")
        return
    if algorithm == "problem5":
        if not 1 <= input_value <= 20:
            expected_from_source = -1
        else:
            expected_from_source = 1
            for value in range(2, input_value + 1):
                expected_from_source = (expected_from_source * value
                                        // math.gcd(expected_from_source, value))
        if expected_result != expected_from_source:
            raise ValueError("problem5 expected_result must match the bounded least common multiple")
        return
    if algorithm == "problem6":
        if not 0 <= input_value <= 100:
            expected_from_source = -1
        else:
            sum_values = input_value * (input_value + 1) // 2
            sum_squares = input_value * (input_value + 1) * (2 * input_value + 1) // 6
            expected_from_source = sum_values * sum_values - sum_squares
        if expected_result != expected_from_source:
            raise ValueError("problem6 expected_result must match the bounded square-of-sum minus sum-of-squares formula")
        return
    if algorithm == "problem7":
        if not 1 <= input_value <= 10_001:
            expected_from_source = -1
        else:
            expected_from_source = primes_for_problem7()[input_value - 1]
        if expected_result != expected_from_source:
            raise ValueError("problem7 expected_result must match the bounded one-based prime index")
        return
    if algorithm == "problem8":
        if not 1 <= input_value <= 13:
            expected_from_source = -1
        else:
            expected_from_source = max(
                math.prod(int(digit) for digit in PROBLEM8_DIGITS[start:start + input_value])
                for start in range(len(PROBLEM8_DIGITS) - input_value + 1)
            )
        if expected_result != expected_from_source:
            raise ValueError("problem8 expected_result must match the maximum product across all legal windows")
        return
    if algorithm == "problem9":
        if not 3 <= input_value <= 1000:
            expected_from_source = -1
        else:
            expected_from_source = -1
            for first in range(1, input_value // 3 + 1):
                for second in range(first + 1, (input_value - first - 1) // 2 + 1):
                    third = input_value - first - second
                    if first * first + second * second == third * third:
                        expected_from_source = first * second * third
                        break
                if expected_from_source != -1:
                    break
        if expected_result != expected_from_source:
            raise ValueError("problem9 expected_result must match the bounded first Pythagorean-triple product")
        return
    if algorithm == "problem10":
        if not 0 <= input_value <= 2_000_000:
            expected_from_source = -1
        else:
            is_prime = bytearray(b"\x01") * input_value
            if input_value > 0:
                is_prime[0] = 0
            if input_value > 1:
                is_prime[1] = 0
            for prime in range(2, math.isqrt(max(0, input_value - 1)) + 1):
                if is_prime[prime]:
                    is_prime[prime * prime:input_value:prime] = b"\x00" * (
                        ((input_value - 1 - prime * prime) // prime) + 1
                    )
            expected_from_source = sum(
                value for value, flag in enumerate(is_prime) if flag
            )
        if expected_result != expected_from_source:
            raise ValueError("problem10 expected_result must match the sum of primes strictly below the bound")
        return
    if algorithm == "problem10_ruby_prefix":
        expected_from_source = problem10_ruby_prefix_source_result(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem10_ruby_prefix expected_result must match the pinned cumulative-prime prefix scan")
        return
    if algorithm == "problem12":
        if not 0 <= input_value <= 500:
            expected_from_source = -1
        else:
            expected_from_source = triangular_number_for_divisor_threshold(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem12 expected_result must match the first triangular number meeting the divisor threshold")
        return
    if algorithm == "problem26":
        if not 0 <= input_value <= 1000:
            expected_from_source = -1
        else:
            best_denominator, longest_remainder_list = 1, 0
            for denominator in range(1, input_value + 1):
                seen = bytearray(denominator + 1)
                remainder, remainder_count = 1, 0
                for _ in range(input_value):
                    if seen[remainder]:
                        if longest_remainder_list < remainder_count:
                            longest_remainder_list = remainder_count
                            best_denominator = denominator
                        break
                    seen[remainder] = 1
                    remainder_count += 1
                    remainder = remainder * 10 % denominator
            expected_from_source = best_denominator
        if expected_result != expected_from_source:
            raise ValueError("problem26 expected_result must match the bounded repeated-remainder search")
        return
    if algorithm == "problem28":
        if not 0 <= input_value <= 100_000:
            expected_from_source = -1
        else:
            expected_from_source = 1
            for layer in range(1, (input_value + 1) // 2):
                odd_corner = 2 * layer + 1
                even_corner = 2 * layer
                expected_from_source += 4 * odd_corner * odd_corner - 6 * even_corner
        if expected_result != expected_from_source:
            raise ValueError("problem28 expected_result must match the bounded spiral-corner recurrence")
        return
    if algorithm == "problem33":
        expected_from_source = problem33_source_result(input_value) if 0 <= input_value <= 5 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem33 expected_result must match the bounded digit-cancelling fraction search")
        return
    if algorithm == "problem38":
        expected_from_source = problem38_source_result() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem38 expected_result must match the fixed concatenated-product search")
        return
    if algorithm == "problem43":
        expected_from_source = problem43_source_result() if input_value == 10 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem43 expected_result must match the fixed permutation divisibility search")
        return
    if algorithm == "problem52":
        expected_from_source = problem52_source_result() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem52 expected_result must match the fixed permuted-multiples search")
        return
    if algorithm == "problem13":
        expected_from_source = 5_537_376_230 if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem13 expected_result must match the fixed-series leading ten-digit sum")
        return
    if algorithm == "problem19":
        expected_from_source = (-1 if input_value != 0 else
                                sum(dt.date(year, month, 1).weekday() == 6
                                    for year in range(1901, 2001)
                                    for month in range(1, 13)))
        if expected_result != expected_from_source:
            raise ValueError("problem19 expected_result must match Sunday month starts from 1901 through 2000")
        return
    if algorithm == "problem23":
        if not 0 <= input_value <= 28_123:
            expected_from_source = -1
        else:
            expected_from_source = problem23_non_abundant_sum(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem23 expected_result must match the inclusive non-abundant-sum bound")
        return
    if algorithm == "problem24":
        expected_from_source = 2_783_915_460 if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem24 expected_result must match the fixed millionth permutation")
        return
    if algorithm == "problem25":
        expected_from_source = (problem25_first_indices_by_digit_count()[input_value - 2]
                                if 2 <= input_value <= 1000 else -1)
        if expected_result != expected_from_source:
            raise ValueError("problem25 expected_result must match the first Fibonacci index with that many digits")
        return
    if algorithm == "problem30":
        expected_from_source = problem30_fixed_sum() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem30 expected_result must match the fixed fifth-power digit search")
        return
    if algorithm == "problem11_sol1":
        expected_from_source = problem11_sol1_source_result() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem11_sol1 expected_result must match the pinned fixed-grid scan")
        return
    if algorithm == "problem29":
        expected_from_source = (problem29_distinct_power_count(input_value)
                                if 1 <= input_value <= 100 else -1)
        if expected_result != expected_from_source:
            raise ValueError("problem29 expected_result must count exact distinct powers in the inclusive domain")
        return
    if algorithm == "problem32":
        expected_from_source = problem32_distinct_product_sum() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem32 expected_result must match the fixed pandigital product sum")
        return
    if algorithm == "problem31":
        expected_from_source = problem31_coin_ways(input_value) if 0 <= input_value <= 500 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem31 expected_result must count unordered standard UK coin combinations")
        return
    if algorithm == "problem31_recursive":
        expected_from_source = problem31_coin_ways(input_value) if 0 <= input_value <= 200 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem31_recursive expected_result must match the un-memoized coin recurrence")
        return
    if algorithm == "problem34":
        expected_from_source = problem34_fixed_sum() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem34 expected_result must match the fixed digit-factorial sum")
        return
    if algorithm == "problem35":
        expected_from_source = problem35_circular_prime_count() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem35 expected_result must match the fixed circular-prime search")
        return
    if algorithm == "problem37":
        expected_from_source = problem37_truncatable_prime_sum() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem37 expected_result must match the fixed truncatable-prime sum")
        return
    if algorithm == "problem31_recursive":
        expected_from_source = problem31_coin_ways(input_value) if 0 <= input_value <= 200 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem31_recursive expected_result must match the bounded coin recurrence")
        return
    if algorithm == "problem36":
        expected_from_source = (-1 if not 0 <= input_value <= 1_000_000 else
                                sum(value for value in problem36_double_base_palindromes()
                                    if value < input_value))
        if expected_result != expected_from_source:
            raise ValueError("problem36 expected_result must sum double-base palindromes below the exclusive limit")
        return
    if algorithm == "problem39":
        expected_from_source = (problem39_nested_side_search(input_value)
                                if 12 <= input_value <= 1000 else -1)
        if expected_result != expected_from_source:
            raise ValueError("problem39 expected_result must match nested-side order and first-inserted perimeter ties")
        return
    if algorithm == "problem40":
        expected_from_source = problem40_champernowne_digit_product() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem40 expected_result must match the seven fixed Champernowne digit positions")
        return
    if algorithm == "problem47":
        expected_from_source = problem47_first_consecutive_base(input_value) if 1 <= input_value <= 4 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem47 expected_result must match the first run with the requested factor count")
        return
    if algorithm == "problem41":
        expected_from_source = problem41_largest_pandigital_prime(input_value) if 1 <= input_value <= 9 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem41 expected_result must match the largest bounded pandigital prime")
        return
    if algorithm == "problem44":
        expected_from_source = problem44_first_pentagonal_difference(input_value) if 1 <= input_value <= 5_000 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem44 expected_result must match the bounded ordered pentagonal search")
        return
    if algorithm == "problem44_start_cursor":
        expected_from_source = problem44_start_cursor_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem44_start_cursor expected_result must match the bounded source-order cursor search")
        return
    if algorithm == "problem46":
        expected_from_source = problem46_goldbach_other_counterexample() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem46 expected_result must match the fixed odd-composite search")
        return
    if algorithm == "problem48":
        expected_from_source = problem48_last_ten_self_powers() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem48 expected_result must match the fixed final ten self-power digits")
        return
    if algorithm == "problem53":
        expected_from_source = problem53_combinations_over_million() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem53 expected_result must count source nCr values strictly above one million")
        return
    if algorithm == "problem49":
        expected_from_source = problem49_prime_permutation_progression() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem49 expected_result must match the fixed prime-permutation progression search")
        return
    if algorithm == "problem50":
        expected_from_source = (problem50_longest_consecutive_prime_sum(input_value)
                                if 3 <= input_value <= 1_000_000 else -1)
        if expected_result != expected_from_source:
            raise ValueError("problem50 expected_result must preserve the consecutive-prime source scan and ties")
        return
    if algorithm == "problem55":
        expected_from_source = (problem55_lychrel_candidate_count(input_value)
                                if 0 <= input_value <= 10_000 else -1)
        if expected_result != expected_from_source:
            raise ValueError("problem55 expected_result must preserve 50 add-then-check iterations")
        return
    if algorithm == "problem51":
        expected_from_source = problem51_default_prime_family() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem51 expected_result must match the fixed filtered eight-prime family")
        return
    if algorithm == "problem57":
        expected_from_source = problem57_sqrt2_expansion_count(input_value) if input_value <= 10_000 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem57 expected_result must count exact sqrt(2) convergent digit-length wins")
        return
    if algorithm == "problem60":
        expected_from_source = problem60_default_prime_chain_sum() if input_value == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem60 expected_result must match the first default concatenable-prime chain")
        return
    if algorithm == "problem64":
        expected_from_source = problem64_odd_period_count(input_value) if 0 <= input_value <= 10_000 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem64 expected_result must count odd periods through the inclusive limit")
        return
    if algorithm == "problem62":
        expected_from_source = problem62_first_cube(input_value) if 1 <= input_value <= 5 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem62 expected_result must match the first cube group reaching the requested size")
        return
    if algorithm == "problem65":
        expected_from_source = problem65_e_convergent_digit_sum(input_value) if 1 <= input_value <= 100 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem65 expected_result must match the e-convergent numerator digit sum")
        return
    if algorithm == "problem68":
        expected_from_source = problem68_first_magic_gon(input_value) if 3 <= input_value <= 5 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem68 expected_result must match the first bounded magic-ring permutation")
        return
    if algorithm == "problem69":
        expected_from_source = problem69_totient_maximizer(input_value) if 1 <= input_value <= 1_000_000 else -1
        if expected_result != expected_from_source:
            raise ValueError("problem69 expected_result must match the inclusive totient-ratio scan and earliest ties")
        return
    if algorithm == "problem45":
        expected_from_source = (problem45_first_hexagonal_pentagonal(input_value)
                                if 0 <= input_value <= 27_693 else -1)
        if expected_result != expected_from_source:
            raise ValueError("problem45 expected_result must match the first bounded hexagonal pentagonal number")
        return
    if algorithm == "problem21":
        if not 1 <= input_value <= 10_000:
            expected_from_source = -1
        else:
            expected_from_source = 0
            for value in range(1, input_value):
                partner = proper_divisor_sum_for_problem21(value)
                if partner != value and proper_divisor_sum_for_problem21(partner) == value:
                    expected_from_source += value
        if expected_result != expected_from_source:
            raise ValueError("problem21 expected_result must match the bounded amicable-number sum")
        return
    if algorithm == "problem21_pair_sum":
        expected_from_source = problem21_pair_sum_expected(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem21_pair_sum expected_result must include both values of each qualifying pair")
        return
    if algorithm == "problem27":
        if not 1 <= input_value <= 1_000:
            expected_from_source = -1
        else:
            best_length, best_product = 0, 0
            for a in range(1 - input_value, input_value):
                for b in range(2, input_value):
                    if not problem27_is_prime(b):
                        continue
                    length, n = 0, 0
                    while problem27_is_prime(n * n + a * n + b):
                        length += 1
                        n += 1
                    if length > best_length:
                        best_length, best_product = length, a * b
            expected_from_source = best_product
        if expected_result != expected_from_source:
            raise ValueError("problem27 expected_result must match the first longest quadratic-prime coefficient pair")
        return
    if algorithm == "problem14":
        if not 1 <= input_value <= 1_000_000:
            expected_from_source = -1
        else:
            expected_from_source = problem14_best_start(input_value)
        if expected_result != expected_from_source:
            raise ValueError("problem14 expected_result must match the smallest start with the longest Collatz chain")
        return
    if algorithm == "isautomorphic":
        if not -3_037_000_499 <= input_value <= 3_037_000_499:
            expected_from_source = -1
        elif input_value < 0:
            expected_from_source = 0
        else:
            square = input_value * input_value
            expected_from_source = int(square % (10 ** len(str(input_value))) == input_value)
        if expected_result != expected_from_source:
            raise ValueError("isautomorphic expected_result must match the bounded decimal square-suffix predicate")
        return
    if algorithm == "logarithm":
        if not 1 <= input_value <= 4_294_967_295:
            expected_from_source = -1
        else:
            expected_from_source = input_value.bit_length() - 1
        if expected_result != expected_from_source:
            raise ValueError("logarithm expected_result must match floor(log2(input)) on the uint32 domain")
        return
    if algorithm in ("problem15", "problem15_dp"):
        if not 0 <= input_value <= 20:
            expected_from_source = -1
        else:
            expected_from_source = 1
            for factor in range(1, input_value + 1):
                expected_from_source = expected_from_source * (input_value + factor) // factor
        if expected_result != expected_from_source:
            raise ValueError(f"{algorithm} expected_result must match the bounded square-grid path count")
        return
    if algorithm == "problem16":
        if not 0 <= input_value <= 1000:
            expected_from_source = -1
        else:
            expected_from_source = sum(int(digit) for digit in str(1 << input_value))
        if expected_result != expected_from_source:
            raise ValueError("problem16 expected_result must match the decimal digit sum of 2 raised to the exponent")
        return
    if algorithm == "problem17":
        if not 0 <= input_value <= 1000:
            expected_from_source = -1
        else:
            small_words = ("", "one", "two", "three", "four", "five", "six", "seven",
                           "eight", "nine", "ten", "eleven", "twelve", "thirteen",
                           "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen")
            tens_words = ("", "", "twenty", "thirty", "forty", "fifty", "sixty",
                          "seventy", "eighty", "ninety")

            def number_letter_count(value: int) -> int:
                if value < 20:
                    return len(small_words[value])
                if value < 100:
                    return len(tens_words[value // 10]) + len(small_words[value % 10])
                if value < 1000:
                    remainder = value % 100
                    return (len(small_words[value // 100]) + len("hundred")
                            + (len("and") + number_letter_count(remainder) if remainder else 0))
                return len("one") + len("thousand")

            expected_from_source = sum(number_letter_count(value)
                                       for value in range(1, input_value + 1))
        if expected_result != expected_from_source:
            raise ValueError("problem17 expected_result must match British number-letter counts through the limit")
        return
    if algorithm == "problem20":
        if not 0 <= input_value <= 100:
            expected_from_source = -1
        else:
            expected_from_source = sum(int(digit) for digit in str(math.factorial(input_value)))
        if expected_result != expected_from_source:
            raise ValueError("problem20 expected_result must match the decimal digit sum of n factorial")
        return
    if algorithm == "endian_converter":
        if not -(2**31) <= input_value <= 2**31 - 1:
            expected_from_source = -(2**31) - 1
        else:
            unsigned = input_value & 0xFFFFFFFF
            reversed_bytes = (((unsigned & 0x000000FF) << 24)
                              | ((unsigned & 0x0000FF00) << 8)
                              | ((unsigned & 0x00FF0000) >> 8)
                              | ((unsigned & 0xFF000000) >> 24))
            expected_from_source = (reversed_bytes if reversed_bytes < 2**31
                                    else reversed_bytes - 2**32)
        if expected_result != expected_from_source:
            raise ValueError("endian_converter expected_result must match signed int32 byte reversal")
        return
    if algorithm == "byte_encoding_utils":
        expected_from_source = int.from_bytes(
            input_value.to_bytes(8, "little", signed=True), "big", signed=True
        )
        if expected_result != expected_from_source:
            raise ValueError("byte_encoding_utils expected_result must match 64-bit byte reversal")
        return
    if algorithm != "fibonacci_number_golden_ration":
        return
    if not 0 <= input_value <= 70:
        expected_from_source = -1
    elif input_value <= 1:
        expected_from_source = input_value
    else:
        sqrt5 = math.sqrt(5.0)
        phi = (1.0 + sqrt5) / 2.0
        psi = (1.0 - sqrt5) / 2.0
        result = (math.pow(phi, input_value) - math.pow(psi, input_value)) / sqrt5
        expected_from_source = math.floor(result + 0.5)
    if expected_result != expected_from_source:
        raise ValueError("fibonacci_number_golden_ration expected_result must match the bounded Binet formula")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-manifest", type=Path)
    parser.add_argument("--algorithm")
    parser.add_argument("--language")
    parser.add_argument("--source", type=Path)
    parser.add_argument("--executable", type=Path)
    parser.add_argument("--compiler")
    parser.add_argument("--compiler-version")
    parser.add_argument("--build-flags")
    parser.add_argument("--build-command")
    parser.add_argument("--workload", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--samples", type=int)
    parser.add_argument("--warmups", type=int)
    parser.add_argument("--repetitions", type=int)
    args = parser.parse_args()

    metadata_options = (args.algorithm, args.language, args.source, args.executable,
                        args.compiler, args.compiler_version, args.build_flags, args.build_command)
    manifest = None
    if args.build_manifest is not None:
        if any(option is not None for option in metadata_options):
            parser.error("--build-manifest cannot be combined with individual build metadata options")
        manifest_path = args.build_manifest.resolve()
        if not manifest_path.is_file():
            parser.error(f"build manifest file does not exist: {manifest_path}")
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            if manifest.get("family") != "scalar":
                parser.error("build manifest must declare the scalar ABI family")
            algorithm = manifest["algorithm"]
            language = manifest["language"]
            source_path = (ROOT / manifest["source_path"]).resolve()
            binary = manifest["binaries"]["scalar_runner"]
            executable_path = Path(binary["path"]).resolve()
            compiler = manifest["compiler"]
            compiler_version = manifest["compiler_version"]
            build_flags = manifest["build_flags"]
            commands = manifest["commands"]
            build_command = " && ".join(shlex.join(command) for command in commands)
        except (AttributeError, KeyError, TypeError, ValueError) as error:
            parser.error(f"invalid scalar build manifest: {error}")
    else:
        required_options = (args.algorithm, args.language, args.source, args.executable,
                            args.compiler, args.compiler_version, args.build_command)
        if any(option is None for option in required_options):
            parser.error("supply --build-manifest or all individual build metadata options")
        algorithm, language = args.algorithm, args.language
        source_path, executable_path = args.source.resolve(), args.executable.resolve()
        compiler, compiler_version = args.compiler, args.compiler_version
        build_flags, build_command = args.build_flags or "", args.build_command

    letter = algorithm[0].lower() if algorithm and algorithm[0].isalpha() else "0-9"
    workload_path = (args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json").resolve()
    runner_source = ROOT / "benchmarks" / "harness" / "scalar_runner.c"
    output_path = (args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl").resolve()

    for path, label in (
        (workload_path, "workload"),
        (source_path, "source"),
        (executable_path, "executable"),
        (runner_source, "runner source"),
    ):
        if not path.is_file():
            parser.error(f"{label} file does not exist: {path}")
    try:
        source_relative = source_path.relative_to(ROOT).as_posix()
    except ValueError:
        parser.error("--source must be inside the encyclopedia repository")
    if manifest is not None:
        binary = manifest["binaries"]["scalar_runner"]
        if (sha256_file(source_path) != manifest.get("source_sha256")
                or sha256_file(executable_path) != binary.get("sha256")
                or sha256_file(runner_source) != binary.get("harness_sha256")):
            parser.error("build manifest no longer matches its source, binary, or scalar harness")

    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if workload["algorithm"] != algorithm:
        parser.error(f"workload algorithm is {workload['algorithm']!r}, not {algorithm!r}")
    if algorithm == "pollards_rho_factorizing":
        validate_pollards_rho_workload(workload)
    elif algorithm == "multiple_of_3_or_5_term":
        validate_multiple_of_3_or_5_term_workload(workload)
    elif algorithm == "mcgill_chomp":
        validate_mcgill_chomp_workload(workload)
    elif algorithm == "automotive_bitcount":
        validate_automotive_bitcount_workload(workload)
    elif algorithm == "shootout_hash":
        validate_shootout_hash_workload(workload)
    elif algorithm == "freebench_pifft":
        validate_freebench_pifft_workload(workload)
    timing = workload["measurement"]
    sample_count = args.samples if args.samples is not None else int(timing["sample_count"])
    warmup_rounds = args.warmups if args.warmups is not None else int(timing["warmup_rounds"])
    repetitions = (
        args.repetitions
        if args.repetitions is not None
        else int(timing["repetitions_per_sample"])
    )
    if sample_count < 1 or warmup_rounds < 0 or repetitions < 1:
        parser.error("samples and repetitions must be positive; warmups cannot be negative")

    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    environment = {
        "os": platform.system(),
        "os_release": platform.release(),
        "architecture": platform.machine(),
        "cpu_model": platform.processor().strip() or None,
        "logical_cpu_count": os.cpu_count(),
        "python_version": platform.python_version(),
    }
    implementation = {
        "language": language,
        "source_path": source_relative,
        "source_sha256": sha256_file(source_path),
        "runner_source_sha256": sha256_file(runner_source),
        "binary_sha256": sha256_file(executable_path),
        "compiler": compiler,
        "compiler_version": compiler_version,
        "build_flags": build_flags,
        "build_command": build_command,
    }
    if manifest is not None:
        # Preserve the build-time identity: the compiler may have been replaced
        # since this binary was built, even when its version text is unchanged.
        implementation["compiler_sha256"] = manifest.get("compiler_sha256")

    spec_sha256 = sha256_file(workload_path)
    records: list[dict[str, Any]] = []
    for case in workload["cases"]:
        input_value = int(case["input_value"])
        expected_result = int(case["expected_result"])
        validate_expected_result(algorithm, input_value, expected_result)
        command = [
            str(executable_path),
            str(input_value),
            str(expected_result),
            str(sample_count),
            str(warmup_rounds),
            str(repetitions),
        ]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode != 0:
            sys.stderr.write(completed.stderr)
            raise SystemExit(f"scalar runner failed for case {case['id']!r}")
        try:
            raw = json.loads(completed.stdout)
        except json.JSONDecodeError as error:
            raise SystemExit(f"scalar runner emitted invalid JSON for {case['id']!r}: {error}") from error
        if int(raw["observed_result"]) != expected_result:
            raise SystemExit(f"scalar runner returned the wrong result for {case['id']!r}")
        if len(raw["samples_ns"]) != sample_count:
            raise SystemExit(f"scalar runner returned the wrong sample count for {case['id']!r}")

        records.append(
            {
                "schema_version": "1.0.0",
                "run_id": run_id,
                "algorithm": algorithm,
                "implementation": implementation,
                "environment": environment,
                "workload": {
                    "id": workload["id"],
                    "spec_sha256": spec_sha256,
                    "input_length": None,
                    "input_value": input_value,
                    "case": str(case["id"]),
                    "target": None,
                    "expected_result": expected_result,
                },
                "measurement": {
                    "timer": "C clock() process CPU time",
                    "timer_resolution_ns": float(raw["timer_resolution_ns"]),
                    "comparison_model": "scalar_call",
                    "target_comparisons_per_sample": None,
                    "warmup_rounds": warmup_rounds,
                    "repetitions_per_sample": repetitions,
                    "samples_ns": [int(sample) for sample in raw["samples_ns"]],
                    "observed_result": int(raw["observed_result"]),
                    "result_checksum": int(raw["result_checksum"]),
                },
            }
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("a", encoding="utf-8", newline="\n") as output:
        for record in records:
            output.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
    print(f"appended {len(records)} result records to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
