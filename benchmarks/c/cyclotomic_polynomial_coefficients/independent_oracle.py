"""Newton-identity reference using Ramanujan sums for root power sums."""

from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "cyclotomic_polynomial_coefficients"
MAX_N = 32
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 248
WORKSPACE_BYTES = 16_384
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _mobius(value: int) -> int:
    if value == 1:
        return 1
    distinct = 0
    prime = 2
    remaining = value
    while prime * prime <= remaining:
        if remaining % prime == 0:
            remaining //= prime
            distinct += 1
            if remaining % prime == 0:
                return 0
        prime += 1
    if remaining > 1:
        distinct += 1
    return -1 if distinct & 1 else 1


def _divisors(value: int) -> list[int]:
    low: list[int] = []
    high: list[int] = []
    candidate = 1
    while candidate * candidate <= value:
        if value % candidate == 0:
            low.append(candidate)
            other = value // candidate
            if other != candidate:
                high.append(other)
        candidate += 1
    return low + high[::-1]


def _ramanujan_sum(n: int, exponent: int) -> int:
    common = n
    other = exponent
    while other:
        common, other = other, common % other
    return sum(divisor * _mobius(n // divisor) for divisor in _divisors(common))


def newton_coefficients(n: int) -> list[int]:
    """Recover the monic polynomial from primitive-root power sums."""
    degree = sum(1 for value in range(1, n + 1) if _gcd(value, n) == 1)
    sums = [0] + [_ramanujan_sum(n, exponent) for exponent in range(1, degree + 1)]
    descending = [1]
    for k in range(1, degree + 1):
        weighted_sum = sum(descending[k - j] * sums[j] for j in range(1, k + 1))
        quotient, remainder = divmod(-weighted_sum, k)
        if remainder:
            raise ArithmeticError("Newton identity did not produce an integer coefficient")
        descending.append(quotient)
    return descending[::-1]


def _gcd(left: int, right: int) -> int:
    while right:
        left, right = right, left % right
    return left


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if len(values) != 1 or not 1 <= values[0] <= MAX_N:
        return None
    return values[0]


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    n = _parse(values, input_is_null, input_length)
    if n is None:
        return INVALID_RESULT, b""
    result = newton_coefficients(n)
    required = 8 * len(result)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(effective_capacity) is not int or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    return required, struct.pack("<" + "q" * len(result), *result)
