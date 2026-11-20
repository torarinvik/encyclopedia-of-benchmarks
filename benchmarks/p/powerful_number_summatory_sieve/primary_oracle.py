"""Bounded powerful-number summatory sieve reference."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_N = 1
MAX_N = 1_000_000
MAX_VALID_INPUT_LENGTH = 1
MAX_INPUT_LENGTH = 2
MAX_RESULT = MAX_N * (MAX_N + 1) // 2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or len(values) != 1):
        return None
    n = values[0]
    if not MIN_N <= n <= MAX_N:
        return None
    return n


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    n = _parse(values, input_is_null, input_length)
    if n is None:
        return -1

    prime_limit = math.isqrt(n)
    is_prime = bytearray(b"\x01") * (prime_limit + 1)
    if prime_limit >= 0:
        is_prime[0] = 0
    if prime_limit >= 1:
        is_prime[1] = 0
    for prime in range(2, math.isqrt(prime_limit) + 1):
        if is_prime[prime]:
            for composite in range(prime * prime, prime_limit + 1, prime):
                is_prime[composite] = 0
    primes = [value for value in range(2, prime_limit + 1) if is_prime[value]]

    total = [n]  # h(1)=1 and G(N)=N for g(n)=1.

    def enumerate_powerful(start: int, current: int, current_h: int) -> None:
        remaining = n // current
        for prime_index in range(start, len(primes)):
            prime = primes[prime_index]
            if prime > remaining // prime:
                break
            prime_power = prime * prime
            h_power = prime - 1
            while prime_power <= remaining:
                powerful = current * prime_power
                h_value = current_h * h_power
                total[0] += h_value * (n // powerful)
                enumerate_powerful(prime_index + 1, powerful, h_value)
                if prime_power > remaining // prime:
                    break
                prime_power *= prime
                h_power *= prime

    enumerate_powerful(0, 1, 1)
    return total[0]
