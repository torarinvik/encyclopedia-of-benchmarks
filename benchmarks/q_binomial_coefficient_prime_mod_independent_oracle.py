"""Subset-enumeration oracle for the bounded modular q-binomial profile."""

from itertools import combinations

from q_binomial_coefficient_prime_mod_oracle import (
    MAX_OUTPUT_BYTES,
    parse_input,
)


def _enumerate_subsets(n_value, k_value, q_value, modulus):
    if k_value > n_value:
        return 0
    offset = k_value * (k_value - 1) // 2
    total = 0
    for subset in combinations(range(n_value), k_value):
        exponent = sum(subset) - offset
        total = (total + pow(q_value, exponent, modulus)) % modulus
    return total


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    parsed = parse_input(values, input_length=input_length,
                         input_is_null=input_is_null)
    if parsed is None:
        return -1, b""
    modulus, q_value, pairs = parsed
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return -2, b""
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if output_is_null or capacity < len(pairs):
        return -2, b""

    output = bytes(
        _enumerate_subsets(n_value, k_value, q_value, modulus)
        for n_value, k_value in pairs
    )
    return len(output), output
