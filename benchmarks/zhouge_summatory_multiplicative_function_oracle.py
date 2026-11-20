"""Clean-room Zhouge sieve for the bounded multiplicative-function family."""

from __future__ import annotations

from array import array
from collections.abc import Sequence
from math import isqrt

MODULUS = 469_762_049
MAX_N = 10_000_000
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1
WORKSPACE_BYTES = 344_064


def _quotient_layout(n: int, root: int) -> tuple[int, int]:
    high_count = n // root
    while high_count > 1 and n // (high_count - 1) == root:
        high_count -= 1
    return high_count, high_count + root


def _quotient_at(index: int, n: int, root: int, high_count: int, size: int) -> int:
    return n // index if index < high_count else size - index


def _value_index(value: int, n: int, root: int, size: int) -> int:
    return size - value if value <= root else n // value


def _prime_table(limit: int) -> tuple[array, array]:
    smallest = array("I", [0]) * (limit + 1)
    primes = array("q")
    for value in range(2, limit + 1):
        if smallest[value] == 0:
            smallest[value] = value
            primes.append(value)
            if value <= limit // value:
                for multiple in range(value * value, limit + 1, value):
                    if smallest[multiple] == 0:
                        smallest[multiple] = value
    return smallest, primes


def _small_value(value: int, smallest: array, a: int, b: int) -> int:
    result = 1
    remaining = value
    while remaining > 1:
        prime = smallest[remaining]
        exponent = 0
        while remaining % prime == 0:
            remaining //= prime
            exponent += 1
        result = result * ((a * exponent + b * prime) % MODULUS) % MODULUS
    return result


def _zhouge_sum(n: int, a: int, b: int) -> int:
    root = isqrt(n)
    high_count, size = _quotient_layout(n, root)
    smallest, primes = _prime_table(root)
    prime_count = len(primes)

    # Prefixes use ascending primes.  The same interval (sqrt(y), y] is used
    # for the lazy single-prime terms in D and the final g_k sieve correction.
    prefix_sum = array("q", [0]) * (prime_count + 1)
    prefix_g = array("q", [0]) * (prime_count + 1)
    for index, prime in enumerate(primes, 1):
        prefix_sum[index] = (prefix_sum[index - 1] + prime) % MODULUS
        prefix_g[index] = (prefix_g[index - 1] + a + b * prime) % MODULUS

    small_lo = array("I", [0]) * size
    small_hi = array("I", [0]) * size
    simple_cursor = array("I", [0]) * size
    g_cursor = array("I", [0]) * size
    g_zero = array("q", [0]) * size
    g_one = array("q", [0]) * size
    smooth_sum = array("q", [1]) * size
    for index in range(1, size):
        value = _quotient_at(index, n, root, high_count, size)
        lo = 0
        hi = prime_count
        while lo < hi:
            middle = (lo + hi) // 2
            if primes[middle] <= isqrt(value):
                lo = middle + 1
            else:
                hi = middle
        small_lo[index] = lo
        lo = 0
        hi = prime_count
        while lo < hi:
            middle = (lo + hi) // 2
            if primes[middle] <= value:
                lo = middle + 1
            else:
                hi = middle
        small_hi[index] = lo
        simple_cursor[index] = small_hi[index]
        g_cursor[index] = small_lo[index]
        g_zero[index] = value % MODULUS
        left, right = value, value + 1
        if left % 2 == 0:
            left //= 2
        else:
            right //= 2
        g_one[index] = (left % MODULUS) * (right % MODULUS) % MODULUS
        smooth_sum[index] = 1
    def ensure_g(index: int, stage: int) -> None:
        new_cursor = min(small_hi[index], max(small_lo[index], stage))
        old_cursor = g_cursor[index]
        if new_cursor > old_cursor:
            g_zero[index] = (g_zero[index] - (new_cursor - old_cursor)) % MODULUS
            g_one[index] = (g_one[index] - (prefix_sum[new_cursor] - prefix_sum[old_cursor])) % MODULUS
            g_cursor[index] = new_cursor

    for stage, prime in enumerate(primes):
        square = prime * prime
        for index in range(1, size):
            value = _quotient_at(index, n, root, high_count, size)
            if value < square:
                break
            child = _value_index(value // prime, n, root, size)
            ensure_g(child, stage)
            g_zero[index] = (g_zero[index] - g_zero[child]) % MODULUS
            g_one[index] = (g_one[index] - prime * g_one[child]) % MODULUS
    for index in range(1, size):
        ensure_g(index, prime_count)

    # D(y) stores the sum of F(x) for y-smooth x over the already processed
    # larger primes.  Omitted single-prime updates are added from prefix_g on
    # first use, with simple_cursor recording exactly which suffix is pending.
    def ensure_simple(index: int, stage: int) -> None:
        new_cursor = min(small_hi[index], max(small_lo[index], stage + 1))
        old_cursor = simple_cursor[index]
        if new_cursor < old_cursor:
            smooth_sum[index] = (
                smooth_sum[index] + prefix_g[old_cursor] - prefix_g[new_cursor]
            ) % MODULUS
            simple_cursor[index] = new_cursor

    for stage in range(prime_count - 1, -1, -1):
        prime = primes[stage]
        square = prime * prime
        for index in range(1, size):
            value = _quotient_at(index, n, root, high_count, size)
            if value < square:
                break
            ensure_simple(index, stage)
            power = prime
            exponent = 1
            while power <= value:
                child = _value_index(value // power, n, root, size)
                ensure_simple(child, stage)
                prime_power_value = (a * exponent + b * prime) % MODULUS
                smooth_sum[index] = (
                    smooth_sum[index] + prime_power_value * smooth_sum[child]
                ) % MODULUS
                power *= prime
                exponent += 1

    total = smooth_sum[1]
    for value in range(1, root + 1):
        prime_sum_index = _value_index(n // value, n, root, size)
        large_prime_sum = (
            a * (g_zero[prime_sum_index] - 1)
            + b * (g_one[prime_sum_index] - 1)
        ) % MODULUS
        total = (total + _small_value(value, smallest, a, b) * large_prime_sum) % MODULUS
    return total


def expected_result(values: Sequence[int] | None) -> int:
    """Return the bounded summatory value or -1 for malformed input."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return INVALID_RESULT
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT
    n, a, b = values
    if not 1 <= n <= MAX_N or not 0 <= a < MODULUS or not 0 <= b < MODULUS:
        return INVALID_RESULT
    if a == 0 and b == 0:
        return 1
    return _zhouge_sum(n, a, b)
