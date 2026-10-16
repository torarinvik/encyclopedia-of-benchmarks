"""Independent scalar references for bounded integer, bit, and sequence work."""

from __future__ import annotations

MAX_COUNT_SET_BITS_INPUT = (1 << 26) - 1
INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1
MAX_SUM_OF_ODD_NUMBERS_INPUT = 46_340
MAX_NONNEGATIVE_INT32 = INT32_MAX
MAX_SIGNED_INT64 = (1 << 63) - 1
MAX_CARMICHAEL_INPUT = 10_000
MAX_KEITH_INPUT = 999_999
MAX_KYNEA_INDEX = 31
MAX_PADOVAN_INDEX = 156
MAX_PELL_INDEX = 50
MAX_PERRIN_INDEX = 155
MAX_SMITH_INPUT = 2_147_395_599  # strictly below 46_340 squared; keeps the pinned int loop safe
MAX_SPHENIC_INPUT = 1_000


def count_set_bits(value: int) -> int:
    """Count one-bits across every integer in the inclusive prefix 1..value."""
    if not 0 <= value <= MAX_COUNT_SET_BITS_INPUT:
        return -1

    total_values = value + 1
    bit = 1
    total_set_bits = 0
    while bit <= value:
        full_cycles, remainder = divmod(total_values, bit * 2)
        total_set_bits += full_cycles * bit + max(0, remainder - bit)
        bit *= 2
    return total_set_bits


def count_leading_zeros(value: int) -> int:
    """Count leading zeros in the source's fixed-width 32-bit representation."""
    if not INT32_MIN <= value <= INT32_MAX:
        return -1
    if value == 0:
        return 32
    return 32 - (value & 0xFFFF_FFFF).bit_length()


def clear_leftmost_set_bit(value: int) -> int:
    """Clear the highest set bit of a nonnegative signed-32-bit value."""
    if not 0 <= value <= MAX_NONNEGATIVE_INT32:
        return -1
    if value == 0:
        return 0
    return value ^ (1 << (value.bit_length() - 1))


def clear_lowest_set_bit(value: int) -> int:
    """Clear the least significant set bit of a nonnegative signed-32-bit value."""
    if not 0 <= value <= MAX_NONNEGATIVE_INT32:
        return -1
    return value & (value - 1)


def sum_of_odd_numbers(count: int) -> int:
    """Return the sum of the first count positive odd integers."""
    if not 0 <= count <= MAX_SUM_OF_ODD_NUMBERS_INPUT:
        return -1
    return count * count


def evil_number(value: int) -> int:
    """Classify a nonnegative signed-64-bit integer by popcount parity."""
    if not 0 <= value <= MAX_SIGNED_INT64:
        return -1
    return int(value.bit_count() % 2 == 0)


def carmichael_number(value: int) -> int:
    """Apply Korselt's criterion to detect Carmichael numbers through 10,000."""
    if not 1 <= value <= MAX_CARMICHAEL_INPUT:
        return -1
    if value < 3:
        return 0

    remaining = value
    prime_factors: list[int] = []
    factor = 2
    while factor <= remaining // factor:
        if remaining % factor == 0:
            exponent = 0
            while remaining % factor == 0:
                remaining //= factor
                exponent += 1
            if exponent != 1:
                return 0
            prime_factors.append(factor)
        factor = 3 if factor == 2 else factor + 2
    if remaining > 1:
        prime_factors.append(remaining)

    return int(len(prime_factors) > 1 and all(
        (value - 1) % (prime - 1) == 0 for prime in prime_factors
    ))


def keith_number(value: int) -> int:
    """Check whether a bounded integer is reached by its digit-seeded recurrence."""
    if not 10 <= value <= MAX_KEITH_INPUT:
        return -1
    window = [int(digit) for digit in str(value)]
    while True:
        following = sum(window)
        if following == value:
            return 1
        if following > value:
            return 0
        window = window[1:] + [following]


def kynea_numbers(index: int) -> int:
    """Return the pinned one-based Kynea term while it fits signed 64-bit."""
    if not 1 <= index <= MAX_KYNEA_INDEX:
        return -1
    value = (1 << index) + 1
    return value * value - 2


def padovan_sequence(index: int) -> int:
    """Return P(index) for Padovan seeds 1, 1, 1 and P(n)=P(n-2)+P(n-3)."""
    if not 0 <= index <= MAX_PADOVAN_INDEX:
        return -1
    if index <= 2:
        return 1
    first, second, third = 1, 1, 1
    for _ in range(3, index + 1):
        first, second, third = second, third, first + second
    return third


def pell_number(index: int) -> int:
    """Return a bounded Pell number using its two-term linear recurrence."""
    if not 0 <= index <= MAX_PELL_INDEX:
        return -1
    previous, current = 0, 1
    for _ in range(index):
        previous, current = current, 2 * current + previous
    return previous


def perrin_number(index: int) -> int:
    """Return the Perrin term with seeds 3, 0, 2."""
    if not 0 <= index <= MAX_PERRIN_INDEX:
        return -1
    terms = [3, 0, 2]
    while len(terms) <= index:
        terms.append(terms[-2] + terms[-3])
    return terms[index]


def smith_number(value: int) -> int:
    """Compare a composite's digit sum with the sum for its prime factors."""
    if not 1 <= value <= MAX_SMITH_INPUT:
        return -1
    original_digit_sum = sum(int(digit) for digit in str(value))
    remaining = value
    factor, factor_digit_sum, factor_count = 2, 0, 0
    while factor <= remaining // factor:
        while remaining % factor == 0:
            remaining //= factor
            factor_count += 1
            factor_digit_sum += sum(int(digit) for digit in str(factor))
        factor = 3 if factor == 2 else factor + 2
    if remaining > 1:
        factor_count += 1
        factor_digit_sum += sum(int(digit) for digit in str(remaining))
    return int(factor_count > 1 and original_digit_sum == factor_digit_sum)


def sphenic_number(value: int) -> int:
    """Check for exactly three distinct prime factors through the sieve bound."""
    if not 0 <= value <= MAX_SPHENIC_INPUT:
        return -1
    if value < 2:
        return 0

    remaining, distinct_factors = value, 0
    factor = 2
    while factor <= remaining // factor:
        if remaining % factor == 0:
            distinct_factors += 1
            remaining //= factor
            if remaining % factor == 0:
                return 0
        factor = 3 if factor == 2 else factor + 2
    if remaining > 1:
        distinct_factors += 1
    return int(distinct_factors == 3)
