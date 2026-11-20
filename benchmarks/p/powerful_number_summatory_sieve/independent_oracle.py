"""Independent direct factorization reference for the summatory function."""

from __future__ import annotations

from collections.abc import Sequence

MIN_N = 1
MAX_N = 1_000_000
MAX_INPUT_LENGTH = 2


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or len(values) != 1):
        return -1
    n = values[0]
    if not MIN_N <= n <= MAX_N:
        return -1

    smallest_prime_factor = [0] * (n + 1)
    for prime in range(2, n + 1):
        if smallest_prime_factor[prime] == 0:
            smallest_prime_factor[prime] = prime
            if prime <= n // prime:
                for composite in range(prime * prime, n + 1, prime):
                    if smallest_prime_factor[composite] == 0:
                        smallest_prime_factor[composite] = prime

    total = 0
    for number in range(1, n + 1):
        remaining = number
        radical = 1
        while remaining > 1:
            prime = smallest_prime_factor[remaining]
            radical *= prime
            while remaining % prime == 0:
                remaining //= prime
        total += number // radical
    return total
