"""Independent inclusion-exclusion oracle for bounded S(n,k) queries."""

from math import comb, factorial

from stirling_number_of_the_second_kind_small_p_large_n_oracle import (
    INVALID_RESULT,
    MAX_K,
    MAX_N,
    MAX_T,
    MODULUS_MAX,
    MODULUS_MIN,
    is_prime,
)


def stirling_value_by_inclusion_exclusion(n, k, modulus):
    numerator = 0
    for index in range(k + 1):
        power = 1 if index == 0 and n == 0 else pow(index, n, modulus)
        term = comb(k, index) * power
        numerator += term if (k - index) % 2 == 0 else -term
    inverse_factorial = pow(factorial(k), modulus - 2, modulus)
    return numerator % modulus * inverse_factorial % modulus


def expected_result(values):
    if (not isinstance(values, (list, tuple))
            or len(values) < 4
            or len(values) > 2 + 2 * MAX_T
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    count, modulus = values[:2]
    if (not 1 <= count <= MAX_T
            or len(values) != 2 + 2 * count
            or not MODULUS_MIN <= modulus <= MODULUS_MAX
            or not is_prime(modulus)):
        return INVALID_RESULT
    answer = 0
    for case_index in range(count):
        n, k = values[2 + 2 * case_index:4 + 2 * case_index]
        if not 0 <= n <= MAX_N or not 0 <= k <= min(n, MAX_K):
            return INVALID_RESULT
        value = stirling_value_by_inclusion_exclusion(n, k, modulus)
        answer = (answer + (case_index + 1) ** 2 * value) % modulus
    return answer
