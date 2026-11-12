"""Independent truncated-polynomial-power oracle for signed s(n,k)."""

from stirling_number_of_the_first_kind_small_p_large_n_oracle import (
    INVALID_RESULT,
    MAX_K,
    MAX_N,
    MAX_T,
    MODULUS_MAX,
    MODULUS_MIN,
    is_prime,
)


def multiply_truncated(left, right, degree_limit, modulus):
    product = [0] * (degree_limit + 1)
    for left_degree, left_value in enumerate(left):
        if left_value == 0:
            continue
        for right_degree, right_value in enumerate(right):
            degree = left_degree + right_degree
            if degree > degree_limit:
                break
            product[degree] = (
                product[degree] + left_value * right_value
            ) % modulus
    return product


def stirling_value_by_polynomial_power(n, k, modulus):
    quotient, remainder = divmod(n, modulus)
    block_power = [0] * (k + 1)
    block_power[0] = 1
    block = [0] * (k + 1)
    if k >= 1:
        block[1] = modulus - 1
    if modulus <= k:
        block[modulus] = 1

    exponent = quotient
    while exponent:
        if exponent & 1:
            block_power = multiply_truncated(
                block_power, block, k, modulus
            )
        exponent >>= 1
        if exponent:
            block = multiply_truncated(block, block, k, modulus)

    remainder_poly = [0] * (k + 1)
    remainder_poly[0] = 1
    for residue in range(remainder):
        next_poly = [0] * (k + 1)
        for degree, coefficient in enumerate(remainder_poly):
            next_poly[degree] = (-residue * coefficient) % modulus
            if degree < k:
                next_poly[degree + 1] = (
                    next_poly[degree + 1] + coefficient
                ) % modulus
        remainder_poly = next_poly

    return multiply_truncated(block_power, remainder_poly, k, modulus)[k]


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
        value = stirling_value_by_polynomial_power(n, k, modulus)
        answer = (answer + (case_index + 1) ** 2 * value) % modulus
    return answer
