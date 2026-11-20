"""Streaming continued-fraction reference for the bounded SQUFOF profile."""

from __future__ import annotations

from math import gcd, isqrt
from typing import Sequence

ALGORITHM = "squfof_semiprime_factor"
MAX_NUMBER = 1_000_000_000_000
MAX_STEPS = 256
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1
WORKSPACE_BYTES = 512


def _valid(values: Sequence[int] | None, algorithm: str, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int] | None:
    if (algorithm != ALGORITHM or not isinstance(values, (list, tuple))
            or type(input_is_null) is not bool or input_is_null
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) != MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    number, forward_cap, reverse_cap = values
    if (number < 3 or number > MAX_NUMBER or number % 2 == 0
            or not 0 <= forward_cap <= MAX_STEPS
            or not 0 <= reverse_cap <= MAX_STEPS):
        return None
    return number, forward_cap, reverse_cap


def _reverse(number: int, discriminant: int, a: int, p: int,
             q: int, cap: int) -> int:
    root = isqrt(q)
    if root * root != q:
        return 0
    quotient = (a - p) // root
    r = quotient * root + p
    previous_s = root
    s = (discriminant - r * r) // root
    for _ in range(cap):
        next_quotient = (a + r) // s
        next_r = next_quotient * s - r
        if next_r == r:
            factor = gcd(number, r)
            if 1 < factor < number:
                return min(factor, number // factor)
            return 0
        next_s = previous_s + next_quotient * (r - next_r)
        previous_s, s, r = s, next_s, next_r
    return 0


def expected_result(values: Sequence[int] | None,
                    algorithm: str = ALGORITHM,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _valid(values, algorithm, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    number, forward_cap, reverse_cap = parsed
    square_root = isqrt(number)
    if square_root * square_root == number:
        return square_root
    discriminant = 2 * number if number % 4 == 1 else number
    a = isqrt(discriminant)
    previous_q = 1
    q = discriminant - a * a
    p = a
    index = 1
    for _ in range(forward_cap):
        quotient = (a + p) // q
        next_p = quotient * q - p
        next_q = previous_q + quotient * (p - next_p)
        previous_q, q, p = q, next_q, next_p
        index += 1
        if index % 2 == 0:
            factor = _reverse(number, discriminant, a, p, q, reverse_cap)
            if factor:
                return factor
    return 0
