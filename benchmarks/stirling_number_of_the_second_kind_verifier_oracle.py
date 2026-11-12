"""Inclusion-exclusion oracle for second-kind Stirling rows."""

from math import comb, factorial

from stirling_number_of_the_second_kind_oracle import (
    INVALID_RESULT,
    MAX_N,
    MODULUS,
)


def stirling_value_by_inclusion_exclusion(n, k):
    numerator = 0
    for j in range(k + 1):
        term = comb(k, j) * pow(j, n, MODULUS)
        numerator += term if (k - j) % 2 == 0 else -term
    inverse_factorial = pow(factorial(k), MODULUS - 2, MODULUS)
    return (numerator % MODULUS) * inverse_factorial % MODULUS


def expected_result(values):
    if (not isinstance(values, (list, tuple))
            or len(values) != 1
            or type(values[0]) is not int
            or not 0 <= values[0] <= MAX_N):
        return INVALID_RESULT
    n = values[0]
    return sum(
        ((k + 1) ** 3) * stirling_value_by_inclusion_exclusion(n, k)
        for k in range(n + 1)
    ) % MODULUS
