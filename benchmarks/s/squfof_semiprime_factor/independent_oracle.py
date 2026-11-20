"""Table-driven complete-quotient reference for the bounded SQUFOF profile.

This reference advances the standard (m,d,a_n) square-root continued-fraction
state, and uses the invariant S*S_previous = D-R^2 in its reverse walk.
"""

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


def _decode(values: Sequence[int] | None, algorithm: str, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, int] | None:
    if (algorithm != ALGORITHM or not isinstance(values, (list, tuple))
            or type(input_is_null) is not bool or input_is_null
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) != 3
            or any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
                   for value in values)):
        return None
    n, forward_limit, reverse_limit = values
    if (n < 3 or n > MAX_NUMBER or n % 2 == 0
            or forward_limit < 0 or forward_limit > MAX_STEPS
            or reverse_limit < 0 or reverse_limit > MAX_STEPS):
        return None
    return n, forward_limit, reverse_limit


def _symmetric_factor(n: int, d_value: int, a0: int,
                      p_value: int, q_value: int, limit: int) -> int:
    root = isqrt(q_value)
    if root * root != q_value:
        return 0
    offset = (a0 - p_value) // root
    r_value = offset * root + p_value
    s_value = (d_value - r_value * r_value) // root
    for _ in range(limit):
        quotient = (a0 + r_value) // s_value
        following_r = quotient * s_value - r_value
        if following_r == r_value:
            divisor = gcd(n, r_value)
            return min(divisor, n // divisor) if 1 < divisor < n else 0
        # The square-form invariant gives the next denominator directly.
        following_s = (d_value - following_r * following_r) // s_value
        r_value, s_value = following_r, following_s
    return 0


def expected_result(values: Sequence[int] | None,
                    algorithm: str = ALGORITHM,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, algorithm, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, forward_limit, reverse_limit = decoded
    root_n = isqrt(n)
    if root_n * root_n == n:
        return root_n

    d_value = 2 * n if n % 4 == 1 else n
    a0 = isqrt(d_value)
    # Build the bounded sequence using the standard complete-quotient
    # (m,d,a_n) recurrence, rather than the ports' paired P/Q update.
    m_value = 0
    denominator = 1
    partial_quotient = a0
    states: list[tuple[int, int, int]] = []
    for index in range(1, forward_limit + 2):
        next_m = denominator * partial_quotient - m_value
        next_denominator = (d_value - next_m * next_m) // denominator
        next_partial = (a0 + next_m) // next_denominator
        m_value, denominator, partial_quotient = next_m, next_denominator, next_partial
        states.append((index, m_value, denominator))

    # The first tuple is (P1,Q1); a forward step from it produces index 2.
    for index, p_value, q_value in states[1:]:
        if index % 2 != 0:
            continue
        found = _symmetric_factor(n, d_value, a0, p_value, q_value, reverse_limit)
        if found:
            return found
    return 0
