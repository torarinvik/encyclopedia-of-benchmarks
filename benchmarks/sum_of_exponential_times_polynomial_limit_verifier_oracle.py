"""Independent Stirling-number identity for the infinite power sum."""

from __future__ import annotations

from collections.abc import Sequence

from sum_of_exponential_times_polynomial_limit_oracle import (
    INVALID_RESULT,
    MAX_DEGREE,
    MODULUS,
)


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != 2):
        return INVALID_RESULT
    if len(values) != 2 or any(
        type(value) is not int or not -(1 << 63) <= value < (1 << 63)
        for value in values
    ):
        return INVALID_RESULT
    r, degree = values
    if not 0 <= r < MODULUS or r == 1 or not 0 <= degree <= MAX_DEGREE:
        return INVALID_RESULT

    # i^d = sum_k S(d,k) k! binom(i,k), and
    # sum_{i>=0} binom(i,k)r^i = r^k/(1-r)^(k+1).
    stirling = [0] * (degree + 1)
    stirling[0] = 1
    for n in range(1, degree + 1):
        for k in range(n, 0, -1):
            stirling[k] = (stirling[k - 1] + k * stirling[k]) % MODULUS
        stirling[0] = 0

    inverse_denominator = pow((1 - r) % MODULUS, MODULUS - 2, MODULUS)
    factorial = 1
    r_power = 1
    inverse_power = inverse_denominator
    answer = 0
    for k in range(degree + 1):
        if k > 0:
            factorial = factorial * k % MODULUS
            r_power = r_power * r % MODULUS
            inverse_power = inverse_power * inverse_denominator % MODULUS
        term = stirling[k] * factorial % MODULUS
        term = term * r_power % MODULUS
        term = term * inverse_power % MODULUS
        answer = (answer + term) % MODULUS
    return answer


def verify_result(values: Sequence[int] | None, result: int,
                  input_length: int | None = None,
                  input_is_null: bool = False) -> bool:
    return result == expected_result(values, input_length, input_is_null)
