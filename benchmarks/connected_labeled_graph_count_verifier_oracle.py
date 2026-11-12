"""Independent exponential-generating-function oracle via formal inversion."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_N = 512
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) != 1:
        return -1
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N:
        return -1

    factorial = [1] * (n + 1)
    all_graph_count = [1] * (n + 1)
    edge_factor = 1
    for size in range(1, n + 1):
        factorial[size] = factorial[size - 1] * size % MODULUS
        all_graph_count[size] = all_graph_count[size - 1] * edge_factor % MODULUS
        edge_factor = edge_factor * 2 % MODULUS

    inverse_factorial = [1] * (n + 1)
    inverse_factorial[n] = pow(factorial[n], MODULUS - 2, MODULUS)
    for size in range(n, 0, -1):
        inverse_factorial[size - 1] = inverse_factorial[size] * size % MODULUS
    all_egf = [all_graph_count[i] * inverse_factorial[i] % MODULUS for i in range(n + 1)]

    reciprocal = [0] * (n + 1)
    reciprocal[0] = 1
    for degree in range(1, n + 1):
        coefficient = 0
        for term_degree in range(1, degree + 1):
            coefficient += all_egf[term_degree] * reciprocal[degree - term_degree]
            coefficient %= MODULUS
        reciprocal[degree] = (-coefficient) % MODULUS

    derivative_product_coefficient = 0
    for term_degree in range(1, n + 1):
        derivative_product_coefficient += (
            term_degree * all_egf[term_degree] * reciprocal[n - term_degree]
        ) % MODULUS
        derivative_product_coefficient %= MODULUS

    # If A(x) is the EGF of all graphs, log(A(x)) is the EGF of connected graphs.
    # Multiplying its x^n coefficient by n! gives the labeled count.
    return derivative_product_coefficient * factorial[n - 1] % MODULUS
