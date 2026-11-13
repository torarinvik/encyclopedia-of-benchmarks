"""Bounded deterministic Montgomery ECM stage-1 factor detector."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd

MAX_NUMBER = 10_000
MAX_BOUND = 32
MAX_VALID_INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 6
INVALID_RESULT = -1
WORKSPACE_BYTES = 1024
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
STAGE1_PRIMES = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31)

SOURCE_BASIS = [
    {
        "organization": "Library Checker Problems",
        "title": "Factorize (Large), in-progress proposal #1395",
        "url": "https://github.com/yosupo06/library-checker-problems/issues/1395",
        "role": "algorithm-discovery-and-large-factorization-context",
        "license": "upstream repository Apache-2.0; issue metadata only",
    },
    {
        "organization": "Annals of Mathematics",
        "title": "Factoring integers with elliptic curves",
        "url": "https://annals.math.princeton.edu/1987/126-3/p09",
        "role": "ECM factorization algorithm description",
        "license": "published paper; mathematical algorithm only",
    },
    {
        "organization": "Montgomery",
        "title": "Speeding the Pollard and elliptic curve methods of factorization",
        "url": "https://doi.org/10.1090/S0025-5718-1987-0866113-7",
        "role": "Montgomery x-only ladder arithmetic",
        "license": "published paper; mathematical formulas only",
    },
]


def _square_free(number: int) -> bool:
    divisor = 2
    while divisor * divisor <= number:
        if number % (divisor * divisor) == 0:
            return False
        divisor += 1
    return True


def _decode(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[int, int, int, int, int] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values)
    if input_length is None:
        input_length = actual_length
    if (
        type(input_length) is not int
        or input_length != actual_length
        or actual_length != MAX_VALID_INPUT_LENGTH
        or actual_length > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    number, curve_a, point_x, point_y, bound = values
    if (
        number < 3
        or number > MAX_NUMBER
        or number % 2 == 0
        or bound < 2
        or bound > MAX_BOUND
        or not 0 <= curve_a < number
        or not 0 <= point_x < number
        or not 0 <= point_y < number
        or not _square_free(number)
    ):
        return None
    if gcd((curve_a * curve_a - 4) % number, number) != 1:
        return None
    rhs = (point_x * point_x % number * point_x
           + curve_a * point_x * point_x + point_x) % number
    if point_y * point_y % number != rhs:
        return None
    return number, curve_a, point_x, point_y, bound


def _x_double(point: tuple[int, int], a24: int, modulus: int) -> tuple[int, int]:
    x, z = point
    plus = (x + z) % modulus
    minus = (x - z) % modulus
    plus_sq = plus * plus % modulus
    minus_sq = minus * minus % modulus
    delta = (plus_sq - minus_sq) % modulus
    doubled_x = plus_sq * minus_sq % modulus
    doubled_z = delta * (minus_sq + a24 * delta) % modulus
    return doubled_x, doubled_z


def _x_add(
    left: tuple[int, int],
    right: tuple[int, int],
    difference: tuple[int, int],
    modulus: int,
) -> tuple[int, int]:
    left_x, left_z = left
    right_x, right_z = right
    diff_x, diff_z = difference
    first = (left_x - left_z) * (right_x + right_z) % modulus
    second = (left_x + left_z) * (right_x - right_z) % modulus
    sum_term = (first + second) % modulus
    difference_term = (first - second) % modulus
    result_x = diff_z * sum_term * sum_term % modulus
    result_z = diff_x * difference_term * difference_term % modulus
    return result_x, result_z


def _x_multiply(
    point: tuple[int, int], scalar: int, a24: int, modulus: int
) -> tuple[int, int]:
    r0 = (1, 0)
    r1 = point
    for bit in range(scalar.bit_length() - 1, -1, -1):
        if scalar & (1 << bit):
            r0 = _x_add(r0, r1, point, modulus)
            r1 = _x_double(r1, a24, modulus)
        else:
            r1 = _x_add(r0, r1, point, modulus)
            r0 = _x_double(r0, a24, modulus)
    return r0


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return 1 iff one stage-1 checkpoint exposes a proper factor, else 0."""
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    number, curve_a, point_x, _point_y, bound = parsed
    inverse_four = (number + 1) // 4 if number % 4 == 3 else (3 * number + 1) // 4
    a24 = (curve_a + 2) * inverse_four % number
    point = (point_x, 1)
    for prime in STAGE1_PRIMES:
        if prime > bound:
            break
        prime_power = prime
        while prime_power <= bound // prime:
            prime_power *= prime
        point = _x_multiply(point, prime_power, a24, number)
        divisor = gcd(point[1], number)
        if 1 < divisor < number:
            return 1
        if divisor == number:
            return 0
    return 0
