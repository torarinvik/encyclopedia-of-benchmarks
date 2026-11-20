"""Direct segmented-factorization reference for the Zhouge benchmark."""

from __future__ import annotations

from collections.abc import Sequence
from math import isqrt

from zhouge_summatory_multiplicative_function_oracle import (
    INVALID_RESULT,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MODULUS,
)

ORACLE_BLOCK_SIZE = 4096


def _direct_sum(n: int, a: int, b: int) -> int:
    if a == 0 and b == 0:
        return 1
    smallest = list(range(isqrt(n) + 1))
    if len(smallest) > 1:
        smallest[1] = 1
    for prime in range(2, isqrt(n) + 1):
        if smallest[prime] == prime:
            for multiple in range(prime * prime, len(smallest), prime):
                if smallest[multiple] == multiple:
                    smallest[multiple] = prime
    primes = [value for value in range(2, len(smallest)) if smallest[value] == value]

    total = 0
    for start in range(1, n + 1, ORACLE_BLOCK_SIZE):
        end = min(n, start + ORACLE_BLOCK_SIZE - 1)
        remaining = list(range(start, end + 1))
        function_values = [1] * len(remaining)
        for prime in primes:
            if prime > end:
                break
            multiple = ((start + prime - 1) // prime) * prime
            while multiple <= end:
                offset = multiple - start
                exponent = 0
                while remaining[offset] % prime == 0:
                    remaining[offset] //= prime
                    exponent += 1
                if exponent:
                    local = (a * exponent + b * prime) % MODULUS
                    function_values[offset] = function_values[offset] * local % MODULUS
                multiple += prime
        for offset, leftover in enumerate(remaining):
            if leftover > 1:
                function_values[offset] = (
                    function_values[offset] * ((a + b * leftover) % MODULUS)
                ) % MODULUS
        total = (total + sum(function_values)) % MODULUS
    return total


def expected_result(values: Sequence[int] | None) -> int:
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
    return _direct_sum(n, a, b)
