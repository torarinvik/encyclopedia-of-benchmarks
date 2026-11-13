"""Independent affine-curve oracle for the bounded ECM stage-1 profile."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd, isqrt

MAX_NUMBER = 10_000
MAX_BOUND = 32
MAX_VALID_INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 6
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
STAGE1_PRIMES = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31)


def _factor_square_free(number: int) -> tuple[int, ...] | None:
    remainder = number
    factors: list[int] = []
    divisor = 2
    while divisor * divisor <= remainder:
        if remainder % divisor == 0:
            remainder //= divisor
            if remainder % divisor == 0:
                return None
            factors.append(divisor)
        divisor += 1
    if remainder > 1:
        factors.append(remainder)
    return tuple(factors)


def _decode(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[int, int, int, int, int, tuple[int, ...]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    size = len(values)
    if input_length is None:
        input_length = size
    if (
        type(input_length) is not int
        or input_length != size
        or size != MAX_VALID_INPUT_LENGTH
        or size > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values)
    ):
        return None
    number, curve_a, point_x, point_y, bound = values
    if (
        number < 3 or number > MAX_NUMBER or number % 2 == 0
        or not 2 <= bound <= MAX_BOUND
        or not 0 <= curve_a < number
        or not 0 <= point_x < number
        or not 0 <= point_y < number
    ):
        return None
    factors = _factor_square_free(number)
    if factors is None:
        return None
    if gcd(curve_a * curve_a - 4, number) != 1:
        return None
    if (point_y * point_y - point_x * point_x * point_x
            - curve_a * point_x * point_x - point_x) % number != 0:
        return None
    return number, curve_a, point_x, point_y, bound, factors


def _add(
    left: tuple[int, int] | None,
    right: tuple[int, int] | None,
    curve_a: int,
    prime: int,
) -> tuple[int, int] | None:
    if left is None:
        return right
    if right is None:
        return left
    x1, y1 = left
    x2, y2 = right
    if x1 == x2 and (y1 + y2) % prime == 0:
        return None
    if left == right:
        denominator = (2 * y1) % prime
        numerator = (3 * x1 * x1 + 2 * curve_a * x1 + 1) % prime
    else:
        denominator = (x2 - x1) % prime
        numerator = (y2 - y1) % prime
    if denominator == 0:
        return None
    slope = numerator * pow(denominator, -1, prime) % prime
    x3 = (slope * slope - curve_a - x1 - x2) % prime
    y3 = (slope * (x1 - x3) - y1) % prime
    return x3, y3


def _multiply(
    point: tuple[int, int] | None,
    scalar: int,
    curve_a: int,
    prime: int,
) -> tuple[int, int] | None:
    result: tuple[int, int] | None = None
    addend = point
    while scalar:
        if scalar & 1:
            result = _add(result, addend, curve_a, prime)
        addend = _add(addend, addend, curve_a, prime)
        scalar >>= 1
    return result


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Use field-group points and trial factors, not Montgomery x-only arithmetic."""
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    number, curve_a, point_x, point_y, bound, factors = parsed
    point_states = [
        (point_x % prime, point_y % prime)
        for prime in factors
    ]
    for stage_prime in STAGE1_PRIMES:
        if stage_prime > bound:
            break
        prime_power = stage_prime
        while prime_power <= bound // stage_prime:
            prime_power *= stage_prime
        point_states = [
            _multiply(point, prime_power, curve_a % factor, factor)
            for point, factor in zip(point_states, factors)
        ]
        infinity_count = sum(point is None for point in point_states)
        if 0 < infinity_count < len(factors):
            return 1
        if infinity_count == len(factors):
            return 0
    return 0
