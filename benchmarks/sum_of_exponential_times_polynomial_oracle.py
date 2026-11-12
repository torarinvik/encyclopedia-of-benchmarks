"""Binary block-composition oracle for finite geometric power sums."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998244353
MAX_DEGREE = 32
MAX_N = 10**18
MAX_INPUT_VALUES = 3
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, int, int] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return None
    if not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if length != MAX_INPUT_VALUES or len(values) != length:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    r, degree, n = values
    if not 0 <= r < MODULUS or not 0 <= degree <= MAX_DEGREE or not 0 <= n <= MAX_N:
        return None
    return r, degree, n


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Return ``sum(r**i * i**d, i=0..n-1)`` modulo 998244353, or -1."""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT
    r, degree, n = parsed

    # Pascal coefficients let each block's moment vector be shifted by its
    # starting index: (a+j)^d = sum_k C(d,k) a^(d-k) j^k.
    choose = [[0] * (degree + 1) for _ in range(degree + 1)]
    choose[0][0] = 1
    for d in range(1, degree + 1):
        choose[d][0] = choose[d][d] = 1
        for k in range(1, d):
            choose[d][k] = (choose[d - 1][k - 1] + choose[d - 1][k]) % MODULUS

    def shift_moments(source: list[int], shift: int) -> list[int]:
        powers = [1] * (degree + 1)
        shift %= MODULUS
        for exponent in range(1, degree + 1):
            powers[exponent] = powers[exponent - 1] * shift % MODULUS
        shifted = [0] * (degree + 1)
        for d in range(degree + 1):
            total = 0
            for k in range(d + 1):
                term = choose[d][k] * powers[d - k] % MODULUS
                total = (total + term * source[k]) % MODULUS
            shifted[d] = total
        return shifted

    accumulated = [0] * (degree + 1)
    block = [0] * (degree + 1)
    block[0] = 1  # Includes the convention 0^0 = 1.
    accumulated_power = 1
    block_power = r
    accumulated_length = 0
    block_length = 1
    remaining = n
    while remaining > 0:
        if remaining & 1:
            appended = shift_moments(block, accumulated_length)
            for d in range(degree + 1):
                accumulated[d] = (
                    accumulated[d] + accumulated_power * appended[d]
                ) % MODULUS
            accumulated_power = accumulated_power * block_power % MODULUS
            accumulated_length += block_length

        second_half = shift_moments(block, block_length)
        for d in range(degree + 1):
            block[d] = (block[d] + block_power * second_half[d]) % MODULUS
        block_power = block_power * block_power % MODULUS
        block_length <<= 1
        remaining >>= 1
    return accumulated[degree]
